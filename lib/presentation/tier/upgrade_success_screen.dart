import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';

class UpgradeSuccessScreen extends StatelessWidget {
  final UpgradeTier tier;

  const UpgradeSuccessScreen({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: const SizedBox(), // No back button
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.black,
              size: AppLayout.scaleWidth(context, 24),
            ),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Success Icon
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: const BoxDecoration(
                color: Color(0xFF069494),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: AppLayout.scaleWidth(context, 40),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Success Message
            Text(
              'Successfully Upgraded to ${tier.name}',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Benefits Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Column(
                children: tier.benefits.map((benefit) {
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: AppLayout.scaleHeight(context, 16)),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: AppLayout.scaleWidth(context, 20),
                          color: const Color(0xFF069494),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 12)),
                        Expanded(
                          child: Text(
                            benefit.title,
                            style: GoogleFonts.openSans(
                              fontSize: AppLayout.fontSize(context, 14),
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        if (benefit.value != null)
                          Text(
                            benefit.value!,
                            style: GoogleFonts.openSans(
                              fontSize: AppLayout.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: AppLayout.scaleWidth(context, 10),
              offset: Offset(0, -AppLayout.scaleHeight(context, 4)),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF069494),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              ),
              elevation: 0,
            ),
            child: Text(
              'Done',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
