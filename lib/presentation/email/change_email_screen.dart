import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/email/change_email_steps_screen.dart';
import 'package:kudipay/provider/email/email_provider.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';

class ChangeEmailScreen extends ConsumerWidget {
  const ChangeEmailScreen({super.key});

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
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Email Icon
                      Container(
                        width: AppLayout.scaleWidth(context, 80),
                        height: AppLayout.scaleWidth(context, 80),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: AppLayout.scaleWidth(context, 40),
                          color: const Color(0xFF5C7C6F),
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 24)),

                      // Current Email Label
                      Text(
                        'Current Email',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),

                      // Current Email Value
                      Text(
                        emailChangeState.maskedEmail ?? 'a*******l@gmail.com',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 18),
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Change Email Button
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: emailChangeState.isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmailChangeStepsScreen(),
                            ),
                          );
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
                          'Change Email',
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
