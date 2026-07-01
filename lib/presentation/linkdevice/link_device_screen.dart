import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/linkdevice/get_verification_code_screen.dart';
import 'package:kudipay/presentation/linkdevice/verify_id.dart';
import 'package:kudipay/provider/provider.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceLinkingProvider.notifier).loadUserDeviceInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceLinkingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      // FIX: Use Column instead of Stack so the button never overlaps the body.
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF069494)),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildBody(context, state)),
                  _buildButton(context),
                ],
              ),
            ),
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

  Widget _buildBody(BuildContext context, DeviceLinkingState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 120)),

          // _buildIcon(context),

          // SizedBox(height: AppLayout.scaleHeight(context, 40)),

          Text(
            'Link your account to this device',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 26),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          Text(
            'To keep your account secure, we need to verify that it\'s really you. This will only take a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          _buildSecurityCard(context),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 88),
      height: AppLayout.scaleWidth(context, 88),
      decoration: const BoxDecoration(
        color: Color(0xFF069494),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 44),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Container(
      // FIX: full width so text doesn't overflow on small screens
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: BoxBorder.all(color: AppColors.textGrey, width: 0.2)),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: const Color(0xFF069494),
            size: AppLayout.scaleWidth(context, 18),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 8)),
          // FIX: Wrap text in Expanded so it wraps instead of overflowing
          Expanded(
            child: Text(
              'Your data is protected with bank-level security',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GetVerificationCodeScreen(),
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
                'Get verification code',
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
                  builder: (context) => const VerifyIdentityScreen(),
                ),
              );
            },
            child: Text(
              'I don\'t have access to my old phone',
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
