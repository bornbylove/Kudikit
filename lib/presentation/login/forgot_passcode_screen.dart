// lib/presentation/login/forgot_passcode_screen.dart
//
// Self-service passcode reset against kudikit_auth_service (PRD "Forgot
// Passcode Flow"), replacing the old "coming soon" sheet:
//
//   1. POST /auth/send-otp    { identifier, purpose: FORGOT_PASSCODE }
//   2. POST /auth/verify-otp  { otpReference, code, purpose: FORGOT_PASSCODE }
//   3. POST /auth/forgot-passcode/reset { otpReference, newPasscode, confirmPasscode }
//
// The server never reveals whether an account exists for the identifier (an
// unknown identifier still gets an OTP reference back), so step 2's copy is
// deliberately conditional. A successful reset revokes every session for the
// account and clears its failed-login lock; pops with `true` so LoginPage can
// tell the user to log in with the new passcode.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:pinput/pinput.dart';

enum _Step { identifier, code, passcode }

class ForgotPasscodeScreen extends ConsumerStatefulWidget {
  /// Prefills the identifier step (whatever the login screen currently shows).
  final String? initialIdentifier;

  const ForgotPasscodeScreen({super.key, this.initialIdentifier});

  @override
  ConsumerState<ForgotPasscodeScreen> createState() =>
      _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends ConsumerState<ForgotPasscodeScreen> {
  static const _brand = Color(0xFF069494);
  static const _errorRed = Color(0xFFE53935);

  final _identifierCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Step _step = _Step.identifier;
  bool _busy = false;
  bool _passcodeVisible = false;
  String? _error;

  String? _otpReference;
  String _maskedIdentifier = '';

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _identifierCtrl.text = widget.initialIdentifier ?? '';
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _identifierCtrl.dispose();
    _otpCtrl.dispose();
    _passcodeCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Runs one network step with shared busy/error handling.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    if (!ref.read(currentConnectivityProvider)) {
      ConnectivitySnackBar.showNoInternet(context);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on KudiNetworkException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on KudiTimeoutException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on KudiApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() {
    return _run(() async {
      final identifier = _identifierCtrl.text.trim();
      if (identifier.isEmpty) {
        setState(() => _error = 'Enter your phone number or email');
        return;
      }
      final response = await ref.read(authServiceProvider).sendOtp(
            identifier: identifier,
            purpose: OtpPurpose.forgotPasscode,
          );
      final data = response['data'] as Map<String, dynamic>?;
      final reference = data?['otpReference'] as String?;
      if (reference == null || reference.isEmpty) {
        throw const KudiApiException(
            'Could not send a code. Please try again.');
      }
      if (!mounted) return;
      _otpCtrl.clear();
      setState(() {
        _otpReference = reference;
        _maskedIdentifier = (data?['maskedIdentifier'] as String?) ?? '';
        _step = _Step.code;
      });
      _startCooldown((data?['resendCooldownSeconds'] as int?) ?? 60);
    });
  }

  Future<void> _verifyCode() {
    return _run(() async {
      final code = _otpCtrl.text.trim();
      if (code.length != 6) {
        setState(() => _error = 'Enter the 6-digit code');
        return;
      }
      await ref.read(authServiceProvider).verifyOtp(
            otpReference: _otpReference!,
            code: code,
            purpose: OtpPurpose.forgotPasscode,
          );
      if (!mounted) return;
      _cooldownTimer?.cancel();
      setState(() => _step = _Step.passcode);
    });
  }

  Future<void> _resetPasscode() {
    return _run(() async {
      final passcode = _passcodeCtrl.text;
      final identifier = normalizeLoginIdentifier(_identifierCtrl.text);

      // Same rules the server's PasscodeValidator enforces, checked locally so
      // the user gets the reason immediately instead of a round-trip 400.
      final ruleError = StorageService.instance.passcodeValidationError(
        passcode,
        phoneNumber: identifier.contains('@') ? null : identifier,
      );
      if (ruleError != null) {
        setState(() => _error = ruleError);
        return;
      }
      if (passcode != _confirmCtrl.text) {
        setState(() => _error = 'Passcodes do not match');
        return;
      }

      await ref.read(authServiceProvider).resetPasscode(
            otpReference: _otpReference!,
            newPasscode: passcode,
            confirmPasscode: _confirmCtrl.text,
          );

      // The passcode changed: whatever this device stored for the old one
      // (lock-screen hash, biometric login credential) is now wrong.
      await StorageService.instance.deletePasscode();
      await StorageService.instance.deleteBiometricCredential();

      if (mounted) Navigator.pop(context, true);
    });
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Colors.black, size: AppLayout.scaleWidth(context, 18)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              switch (_step) {
                _Step.identifier => _buildIdentifierStep(context),
                _Step.code => _buildCodeStep(context),
                _Step.passcode => _buildPasscodeStep(context),
              },
              if (_error != null) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: AppLayout.scaleWidth(context, 14),
                        color: _errorRed),
                    SizedBox(width: AppLayout.scaleWidth(context, 4)),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: _errorRed,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 26),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF171515),
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 10)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 24)),
      ],
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint,
      {Widget? suffixIcon}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: border(const Color(0xFFE0E0E0)),
      focusedBorder: border(_brand),
      disabledBorder: border(const Color(0xFFE0E0E0)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
    );
  }

  Widget _primaryButton(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: AppLayout.scaleHeight(context, 52),
      child: ElevatedButton(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          disabledBackgroundColor: _brand.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
        ),
        child: _busy
            ? const AppLoadingIndicator.button()
            : Text(
                label,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildIdentifierStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          context,
          'Reset your passcode',
          'Enter the phone number or email on your Kudikit account and we\'ll '
              'send you a verification code.',
        ),
        TextField(
          controller: _identifierCtrl,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _sendCode(),
          decoration: _fieldDecoration(context, 'Phone number or email'),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 24)),
        _primaryButton(context, 'Send code', _sendCode),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    final pinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: _brand,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5, color: _brand),
      ),
    );
    final canResend = _cooldownSeconds <= 0 && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          context,
          'Enter the code',
          _maskedIdentifier.isEmpty
              ? 'If an account exists, we\'ve sent a 6-digit code.'
              : 'If an account exists for $_maskedIdentifier, we\'ve sent it a '
                  '6-digit code.',
        ),
        Pinput(
          length: 6,
          controller: _otpCtrl,
          enabled: !_busy,
          defaultPinTheme: pinTheme,
          focusedPinTheme: pinTheme.copyDecorationWith(
            border: Border.all(color: _brand, width: 2),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (_) => _verifyCode(),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 24)),
        _primaryButton(context, 'Verify code', _verifyCode),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Center(
          child: TextButton(
            onPressed: canResend ? _sendCode : null,
            child: Text(
              canResend ? 'Resend code' : 'Resend code in ${_cooldownSeconds}s',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: canResend ? _brand : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasscodeStep(BuildContext context) {
    final visibilityToggle = IconButton(
      icon: Icon(
        _passcodeVisible ? Icons.visibility : Icons.visibility_off,
        size: AppLayout.scaleWidth(context, 20),
      ),
      onPressed: () => setState(() => _passcodeVisible = !_passcodeVisible),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          context,
          'Create a new passcode',
          'Use 6-8 digits. Avoid sequences (123456), repeats (111111) and '
              'parts of your phone number. You\'ll be signed out everywhere '
              'once it\'s changed.',
        ),
        TextField(
          controller: _passcodeCtrl,
          enabled: !_busy,
          obscureText: !_passcodeVisible,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: _fieldDecoration(context, 'New passcode',
              suffixIcon: visibilityToggle),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 14)),
        TextField(
          controller: _confirmCtrl,
          enabled: !_busy,
          obscureText: !_passcodeVisible,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _resetPasscode(),
          decoration: _fieldDecoration(context, 'Confirm new passcode'),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 24)),
        _primaryButton(context, 'Update passcode', _resetPasscode),
      ],
    );
  }
}
