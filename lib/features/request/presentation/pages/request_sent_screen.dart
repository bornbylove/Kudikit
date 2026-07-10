import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/request/domain/entities/request_model.dart';

class RequestSentScreen extends StatelessWidget {
  final MoneyRequest request;

  const RequestSentScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: Text(
          'Preview Request',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: AppLayout.scaleWidth(context, 40),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Success Message
            Text(
              'Request Sent!',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Text(
              'Your money request has been sent to ${request.recipientIds.length} person${request.recipientIds.length > 1 ? 's' : ''}',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Delivery Method
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery method',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  Container(
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppLayout.scaleWidth(context, 40),
                          height: AppLayout.scaleWidth(context, 40),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 8)),
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: AppLayout.scaleWidth(context, 20),
                          ),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In-App Notification',
                                style: GoogleFonts.openSans(
                                  fontSize: AppLayout.fontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${request.recipientIds.length} recipient${request.recipientIds.length > 1 ? 's' : ''} will receive an instant notification',
                                style: GoogleFonts.openSans(
                                  fontSize: AppLayout.fontSize(context, 12),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Recipients
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipients',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: AppLayout.scaleWidth(context, 20),
                        backgroundColor: Colors.black,
                        child: Text(
                          request.requesterName.substring(0, 2).toUpperCase(),
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppLayout.fontSize(context, 14),
                          ),
                        ),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requesterName,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Notified via app',
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 12)),
                  ),
                  elevation: 0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Send Request',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                ),
                child: Text(
                  'Edit Request',
                  style: GoogleFonts.openSans(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
