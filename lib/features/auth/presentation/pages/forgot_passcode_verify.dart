// lib/features/auth/presentation/pages/forgot_passcode_verify.dart
//
// Step 2 of 3 — verifies the 6-digit reset code.
//
// Uses the shared POST /auth/verify-otp with purpose FORGOT_PASSCODE.
// This step cannot be skipped: ResetPasscodeRequest carries no code field, so
// the otpReference must already be verified before the reset call.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/auth/presentation/pages/reset_passcode.dart';
import 'package:pinput/pinput.dart';

/// Resend cooldown reported by send-otp (`resendCooldownSeconds`).
const int _kResendCooldownSeconds = 60;

class ForgotPasscodeVerifyScreen extends ConsumerStatefulWidget {
  final String otpReference;
  final String identifier;

  const ForgotPasscodeVerifyScreen({
    super.key,
    required this.otpReference,
    required this.identifier,
  });

  @override
  ConsumerState<ForgotPasscodeVerifyScreen> createState() =>
      _ForgotPasscodeVerifyScreenState();
}

class _ForgotPasscodeVerifyScreenState
    extends ConsumerState<ForgotPasscodeVerifyScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  late String _currentReference;
  int _resendIn = _kResendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _currentReference = widget.otpReference;
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  // The server enforces a 60s cooldown, so gate the button rather than letting
  // the user tap into a rate-limit error.
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _kResendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await ref.read(verifyForgotPasscodeOtpUseCaseProvider).call(
            otpReference: _currentReference,
            code: code,
          );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasscodeScreen(otpReference: _currentReference),
        ),
      );
    } on KudiApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendIn > 0) return;
    try {
      final reference = await ref
          .read(sendForgotPasscodeOtpUseCaseProvider)
          .call(identifier: widget.identifier);
      if (!mounted) return;
      setState(() {
        _currentReference = reference;
        _otpCtrl.clear();
        _error = null;
      });
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPin = PinTheme(
      width: AppLayout.scaleWidth(context, 48),
      height: AppLayout.scaleWidth(context, 52),
      textStyle: TextStyle(
        fontSize: AppLayout.fontSize(context, 20),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Colors.black, size: AppLayout.scaleWidth(context, 18)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the code',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'We sent a 6-digit code to ${widget.identifier}. '
                'It expires in 5 minutes.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              Pinput(
                controller: _otpCtrl,
                length: 6,
                defaultPinTheme: defaultPin,
                focusedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border: Border.all(color: AppColors.primaryTeal, width: 2),
                  ),
                ),
                onCompleted: (_) => _handleVerify(),
              ),
              if (_error != null) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: AppColors.avatarRed,
                  ),
                ),
              ],
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              Center(
                child: TextButton(
                  onPressed: _resendIn == 0 ? _handleResend : null,
                  child: Text(
                    _resendIn == 0
                        ? 'Resend code'
                        : 'Resend code in ${_resendIn}s',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color:
                          _resendIn == 0 ? AppColors.primaryTeal : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: _isVerifying
                      ? SizedBox(
                          width: AppLayout.scaleWidth(context, 20),
                          height: AppLayout.scaleWidth(context, 20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
