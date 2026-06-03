import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/bottom_nav.dart';

class AccountActiveScreen extends ConsumerWidget {
  const AccountActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
     
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(context)),
            _buildButton(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSuccessIcon(context),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
            Text(
              "You're all set!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppLayout.fontSize(context, 28), fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'Your account is now active on this device. You can start using the app right away.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppLayout.fontSize(context, 14), color: Colors.black54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 120),
      height: AppLayout.scaleWidth(context, 120),
      decoration: const BoxDecoration(color: Color(0xFF069494), shape: BoxShape.circle),
      child: Icon(Icons.check, color: Colors.white, size: AppLayout.scaleWidth(context, 60)),
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
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const BottomNavBar()),
            (_) => false,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF069494),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: Text(
            'Continue to dashboard',
            style: TextStyle(fontSize: AppLayout.fontSize(context, 16), fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}