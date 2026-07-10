// lib/presentation/linkdevice/sign_in_verify_email_screen.dart
//
// "Enter verification code" screen shown after the user selects
// email as their verification method on GetVerificationCodeScreen.
//
// Flow:
//   GetVerificationCodeScreen
//     → SignInVerifyEmailScreen   ← this file
//       → DataSyncScreen
//
// State: deviceLinkingProvider (DeviceLinkingNotifier)
//   - verifyCode(code)     → calls _service.verifyCode → sets isVerified
//   - sendVerificationCode()  → resend OTP
//   - state.isVerifyingCode   → loading overlay
//   - state.error             → inline error display
//
// Connectivity: connectivityProvider + ConnectivitySnackBar (existing pattern)
// Resend timer: 60-second countdown, matches project convention

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/data_sync.dart';
import 'package:kudipay/provider/provider.dart';

class SignInVerifyEmailScreen extends ConsumerStatefulWidget {
  /// Masked email shown in the subtitle  e.g. "u***r@gmail.com"
  final String maskedEmail;

  const SignInVerifyEmailScreen({
    super.key,
    required this.maskedEmail,
  });

  @override
  ConsumerState<SignInVerifyEmailScreen> createState() =>
      _SignInVerifyEmailScreenState();
}

class _SignInVerifyEmailScreenState
    extends ConsumerState<SignInVerifyEmailScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  // Resend cooldown — 60 seconds, matching signup_verify.dart convention
  static const int _resendCooldownSeconds = 60;
  int _secondsRemaining = _resendCooldownSeconds;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
      // Auto-focus the text field
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Connectivity listener ────────────────────────────────────────────────

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  // ── Resend timer ─────────────────────────────────────────────────────────

  void _startResendTimer() {
    _canResend = false;
    _secondsRemaining = _resendCooldownSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ── Verify code ──────────────────────────────────────────────────────────

  Future<void> _handleVerify() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();

    final isValid =
        await ref.read(deviceLinkingProvider.notifier).verifyCode(code);

    if (!mounted) return;

    if (isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DataSyncScreen()),
      );
    } else {
      // Error is set on the provider state — shown via ref.listen below.
      // Also clear the field so the user retypes.
      _codeController.clear();
      _focusNode.requestFocus();
    }
  }

  // ── Resend code ──────────────────────────────────────────────────────────

  Future<void> _handleResend() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      ConnectivitySnackBar.showNoInternet(context);
      return;
    }

    await ref.read(deviceLinkingProvider.notifier).sendVerificationCode();

    if (!mounted) return;

    _codeController.clear();
    _startResendTimer();

    // Show success snackbar if no error was set
    final state = ref.read(deviceLinkingProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code resent to ${widget.maskedEmail}'),
          backgroundColor: const Color(0xFF069494),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceLinkingProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    // Show error from provider state as a snackbar
    ref.listen<DeviceLinkingState>(deviceLinkingProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildBody(context, state, isOnline),
                ),
                _buildContinueButton(context, state, isOnline),
              ],
            ),
          ),
          // Full-screen loading overlay while verifying
          if (state.isVerifyingCode)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF069494),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
          size: AppLayout.scaleWidth(context, 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DeviceLinkingState state,
    bool isOnline,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              'Enter verification code',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 26),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // ── Subtitle ───────────────────────────────────────────────────
            Text(
              'Check your email for the code we just sent you',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // ── "Enter code" label ─────────────────────────────────────────
            Text(
              'Enter code',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // ── Code input field ───────────────────────────────────────────
            _buildCodeField(context, isOnline),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // ── Resend row ─────────────────────────────────────────────────
            _buildResendRow(context, state, isOnline),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeField(BuildContext context, bool isOnline) {
    return TextFormField(
      controller: _codeController,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      enabled: isOnline,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the verification code';
        }
        if (value.length < 6) {
          return 'Code must be 6 digits';
        }
        return null;
      },
      // Auto-submit when 6 digits are entered
      onChanged: (value) {
        if (value.length == 6 && isOnline) {
          _handleVerify();
        }
      },
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 16),
        fontWeight: FontWeight.w500,
        letterSpacing: AppLayout.scaleWidth(context, 3),
        color: isOnline ? Colors.black87 : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: isOnline ? '' : 'Internet required',
        hintStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: Colors.red.shade300,
          letterSpacing: 0,
        ),
        filled: true,
        fillColor: isOnline ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: const BorderSide(
            color: Color(0xFF069494),
            width: 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
      ),
    );
  }

  Widget _buildResendRow(
    BuildContext context,
    DeviceLinkingState state,
    bool isOnline,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ",
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),

        // Show spinner while resending, timer during cooldown, button when ready
        if (state.isSendingCode)
          const SizedBox(
            width: 16,
            height: 16,
            child: AppLoadingIndicator.button(),
          )
        else if (!_canResend)
          Text(
            'Resend code (${_secondsRemaining}s)',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          GestureDetector(
            onTap: (isOnline && !state.isSendingCode) ? _handleResend : null,
            child: Text(
              'Resend code',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: isOnline ? const Color(0xFF069494) : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    DeviceLinkingState state,
    bool isOnline,
  ) {
    final bool isDisabled = state.isVerifyingCode || !isOnline;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 40),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          onPressed: isDisabled
              ? null
              : () {
                  if (!isOnline) {
                    ConnectivitySnackBar.showNoInternet(context);
                  } else {
                    _handleVerify();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF069494),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
            elevation: 0,
          ),
          child: state.isVerifyingCode
              ? const AppLoadingIndicator.button()
              : Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
