import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/presentation/email/verify_otp_email_screen.dart';
import 'package:kudipay/provider/email/email_provider.dart';

class EmailChangeStepsScreen extends ConsumerWidget {
  const EmailChangeStepsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailChangeState = ref.watch(emailChangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Email',
          style: TextStyle(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
                'Change Email',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // Subtitle
              Text(
                'Follow these steps to change your email',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // Steps
              _buildStep(
                context,
                stepNumber: '1',
                title: 'Enter the 6 digit code.',
                isCompleted: false,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              _buildStep(
                context,
                stepNumber: '2',
                title: 'Get Verified.',
                isCompleted: false,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              _buildStep(
                context,
                stepNumber: '3',
                title: 'Change your email',
                isCompleted: false,
              ),

              const Spacer(),

              // Get OTP Button
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: emailChangeState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(emailChangeProvider.notifier)
                              .requestOTP();

                          if (success && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VerifyEmailOtpScreen(),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  emailChangeState.errorMessage ??
                                      'Failed to send OTP',
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
                          'Get OTP',
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

  Widget _buildStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        // Step Number Circle
        Container(
          width: AppLayout.scaleWidth(context, 40),
          height: AppLayout.scaleWidth(context, 40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted ? const Color(0xFF5C7C6F) : const Color(0xFFE8F5E9),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: AppLayout.scaleWidth(context, 20),
                  )
                : Text(
                    stepNumber,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C7C6F),
                    ),
                  ),
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 16)),

        // Step Title
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 15),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
