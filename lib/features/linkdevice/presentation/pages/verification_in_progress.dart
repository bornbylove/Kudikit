import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/core/utils/responsive.dart';

class VerificationInProgressScreen extends ConsumerWidget {
  const VerificationInProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 60)),

            // Icon
            _buildIcon(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Title
            Text(
              'Verification in progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Subtitle
            Text(
              'Thanks for submitting your documents. We\'re\nreviewing them now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Info cards
            _buildInfoCard(
              context,
              icon: Icons.schedule,
              iconColor: const Color(0xFFFFA726),
              title: 'Review time',
              subtitle: 'Usually completed within 24-48 hours',
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            _buildInfoCard(
              context,
              icon: Icons.email_outlined,
              iconColor: const Color(0xFF5E35B1),
              title: 'Email updates',
              subtitle:
                  'We\'ll send you an email as soon as we\'ve\ncompleted the review',
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Restriction notice
            _buildRestrictionNotice(context),

            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Need help section
            _buildNeedHelpSection(context),

            SizedBox(height: AppLayout.scaleHeight(context, 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 80),
      height: AppLayout.scaleWidth(context, 80),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.schedule,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 40),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: AppLayout.scaleWidth(context, 48),
            height: AppLayout.scaleWidth(context, 48),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: AppLayout.scaleWidth(context, 24),
            ),
          ),

          SizedBox(width: AppLayout.scaleWidth(context, 16)),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionNotice(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF1976D2),
            size: AppLayout.scaleWidth(context, 20),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              'Your account is temporarily restricted until verification is complete. This is to keep your money safe.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: const Color(0xFF1565C0),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: AppColors.primaryTeal,
                size: AppLayout.scaleWidth(context, 24),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Text(
                'Need help?',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Text(
            'If you have questions or need assistance, our\nsupport team is here to help.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.support);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Contact support',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 4)),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryTeal,
                    size: AppLayout.scaleWidth(context, 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
