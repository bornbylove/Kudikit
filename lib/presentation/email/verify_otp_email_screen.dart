import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/presentation/email/enter_new_email_screen.dart';
import 'package:kudipay/provider/email/email_provider.dart';

class VerifyEmailOtpScreen extends ConsumerStatefulWidget {
  const VerifyEmailOtpScreen({super.key});

  @override
  ConsumerState<VerifyEmailOtpScreen> createState() =>
      _VerifyEmailOtpScreenState();
}

class _VerifyEmailOtpScreenState extends ConsumerState<VerifyEmailOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailChangeState = ref.watch(emailChangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            ref.read(emailChangeProvider.notifier).goBack();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Title
              Text(
                'Verify Your Identity.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // Subtitle with masked email
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.black54,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to '),
                    TextSpan(
                      text: emailChangeState.maskedEmail ?? 'e***@gmail.com',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // Enter code label
              Text(
                'Enter code',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // OTP Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: '1234543',
                    hintStyle: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      color: Colors.grey[400],
                      letterSpacing: 2,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                      vertical: AppLayout.scaleHeight(context, 16),
                    ),
                    counterText: '',
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.black54,
                    ),
                  ),
                  TextButton(
                    onPressed: emailChangeState.isLoading
                        ? null
                        : () async {
                            final success = await ref
                                .read(emailChangeProvider.notifier)
                                .resendOTP();

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code resent successfully'),
                                  backgroundColor: Color(0xFF069494),
                                ),
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend code',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: const Color(0xFF069494),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: emailChangeState.isLoading ||
                          _otpController.text.length != 6
                      ? null
                      : () async {
                          final success = await ref
                              .read(emailChangeProvider.notifier)
                              .verifyOTP(_otpController.text);

                          if (success && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EnterNewEmailScreen(),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  emailChangeState.errorMessage ??
                                      'Invalid OTP',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: emailChangeState.isLoading
                      ? const AppLoadingIndicator.button()
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ],
          ),
        ),
      ),
    );
  }
}
