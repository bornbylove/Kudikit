import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/account_active.dart';

class EnableBiometricsScreen extends ConsumerWidget {
  const EnableBiometricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildButton(context),
      body: Stack(
        children: [
          _buildBody(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
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
            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Icon
            _buildIcon(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Title
            Text(
              'Secure this device',
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
              'Enable biometric authentication for faster, more\nsecure access to your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Feature cards
            _buildFeatureCard(
              context,
              icon: Icons.lock_outline,
              iconColor: const Color(0xFFE91E63),
              title: 'Extra protection',
              subtitle: 'Your fingerprint is more secure than a\npassword',
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            _buildFeatureCard(
              context,
              icon: Icons.fingerprint,
              iconColor: const Color(0xFF5E35B1),
              title: 'Quick & easy',
              subtitle: 'Sign in with just a touch or glance',
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Info card
            _buildInfoCard(context),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
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
        color: const Color(0xFF5E35B1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.fingerprint,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 40),
      ),
    );
  }

  Widget _buildFeatureCard(
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

  Widget _buildInfoCard(BuildContext context) {
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
              'Your biometric data never leaves your device and is protected by your phone\'s security',
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

  Widget _buildButton(BuildContext context) {
    return Positioned(
      bottom: AppLayout.scaleHeight(context, 40),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: () {
                // Persist the biometrics preference, then proceed.
                // When local_auth is added to pubspec, call
                // LocalAuthentication().authenticate() here first.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountActiveScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Enable Biometrics',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountActiveScreen(),
                ),
              );
            },
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF069494),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
