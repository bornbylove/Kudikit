import 'package:flutter/material.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';


class IntroviewPage extends StatelessWidget {
  const IntroviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = AppLayout.height(context);
    final screenWidth = AppLayout.width(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: screenWidth,
              height: screenHeight * 0.55,
              child: Image.asset(
                'assets/images/introview.png',
                fit: BoxFit.fill,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 24)),

                    // Title
                    Text(
                      'Join the Kudikit Tribe and start\nyour journey today!',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 22),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 32)),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          disabledBackgroundColor:
                              AppColors.primaryTeal.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                          ),
                        ),
                        onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.signup);
                        },
                        child: Text(
                          'Get started',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 17),
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 14)),

                    // Login button — full width, outlined
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          side: const BorderSide(
                            color: AppColors.primaryTeal,
                            width: 1,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 17),
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
