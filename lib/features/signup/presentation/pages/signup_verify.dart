// lib/presentation/signup/signup_verify.dart
//
// FIXED:
//   - Constructor parameter renamed: `pin` ? `passcode`.
//     The old name `pin` was ambiguous — the same word was used inside
//     the Pinput widget for the OTP code, causing a naming collision that
//     made the code confusing and error-prone for future developers.
//   - All internal references updated accordingly.
//   - No logic changes — only naming clarity.

import 'dart:async';
import 'package:kudipay/core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/shared/widgets/color_app_button.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/features/signup/presentation/pages/signup_more_details.dart';
import 'package:kudipay/services/api_services.dart';
import 'package:pinput/pinput.dart';

class EmailVerifySignup extends ConsumerStatefulWidget {
  final String email;
  final String phoneNumber;

  // The user's signup passcode (8-12 char alphanumeric), NOT the 6-digit OTP.
  final String passcode;

  /// The otpId returned by the send-otp step on the previous screen.
  final String otpId;

  const EmailVerifySignup({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.passcode,
    required this.otpId,
  });

  @override
  ConsumerState<EmailVerifySignup> createState() => _EmailVerifySignupState();
}

class _EmailVerifySignupState extends ConsumerState<EmailVerifySignup> {
  // Named `_otpController` to make clear this controls the 6-digit OTP input,
  // not the user's passcode.
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool isLoading = false;
  bool isResending = false;

  /// Tracks the current otpId — updated when the user resends the code.
  late String _currentOtpId;

  @override
  void dispose() {
    _otpController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentOtpId = widget.otpId;

    // OTP was already sent by the signup screen — do NOT send again here.
    // Only set up the connectivity listener.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

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

  Future<void> _sendVerificationCode() async {
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
            title: const Text('No Internet Connection'),
            content: const Text(
              'Sending verification code requires internet. Please check your connection.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(connectivityStateProvider.notifier)
                      .refresh()
                      .then((_) {
                    if (ref.read(currentConnectivityProvider)) {
                      _sendVerificationCode();
                    }
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => isResending = true);

    try {
      final newOtpId = await ref.read(authProvider.notifier).resendVerification(
            email: widget.email,
            phoneNumber: widget.phoneNumber,
          );

      if (mounted) {
        setState(() => _currentOtpId = newOtpId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to ${widget.email}'),
            backgroundColor: const Color.fromARGB(255, 6, 148, 42),
          ),
        );
      }
    } on NoInternetException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  Future<void> _verifyCode() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ref.read(authProvider.notifier).verifyOtpAndRegister(
            otpId: _currentOtpId,
            otp: otp,
            email: widget.email,
            phoneNumber: widget.phoneNumber,
            passcode: widget.passcode,
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KnowYouBetterForm(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: Color.fromARGB(255, 6, 148, 42),
          ),
        );
      }
    } on NoInternetException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: AppColors.primaryTeal,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5, color: AppColors.primaryTeal),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryTeal, width: 2),
      borderRadius: BorderRadius.circular(10),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromARGB(255, 235, 238, 237).withValues(alpha: 0.8),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isOnline)
            Padding(
              padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 8)),
              child: const Center(child: ConnectivityIndicator()),
            ),
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.50,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '50%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade700,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verification requires internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(connectivityStateProvider.notifier).refresh();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify your Identity',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isSmallScreen ? 23 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter the 6-digit code sent to ${widget.email} and ${widget.phoneNumber}',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter code',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // OTP input — 6 digits only. This is NOT the passcode.
                      Pinput(
                        length: 6,
                        controller: _otpController,
                        focusNode: _pinFocusNode,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        pinAnimationType: PinAnimationType.fade,
                        enabled: isOnline && !isLoading,
                        onCompleted: (enteredOtp) {
                          if (isOnline) {
                            _verifyCode();
                          } else {
                            ConnectivitySnackBar.showNoInternet(context);
                          }
                        },
                      ),

                      if (!isOnline)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Internet required to verify code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      if (isLoading)
                        const AppLoadingIndicator()
                      else if (!isOnline)
                        Opacity(
                          opacity: 0.5,
                          child: ColorAppButton(
                            press: () {
                              ConnectivitySnackBar.showNoInternet(context);
                            },
                            text: 'No Internet Connection',
                          ),
                        )
                      else
                        ColorAppButton(
                          press: _verifyCode,
                          text: 'Continue',
                        ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive code? ",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          if (isResending)
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: AppLoadingIndicator.button())
                          else
                            TextButton(
                              onPressed: isOnline
                                  ? _sendVerificationCode
                                  : () {
                                      ConnectivitySnackBar.showNoInternet(
                                          context);
                                    },
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isOnline
                                      ? AppColors.primaryTeal
                                      : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Change email',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
