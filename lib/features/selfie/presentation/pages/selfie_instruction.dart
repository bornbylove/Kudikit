import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/selfie/presentation/pages/selfie_capture_screen.dart';

class SelfieInstructionsScreen extends ConsumerWidget {
  const SelfieInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.36,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF069494)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '36%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Text(
              'Photo Capture',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Text(
              'We\'ll match your face with your NIN/BVN photo to verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 60)),
            // Face Detection Icon
            Container(
              width: AppLayout.scaleWidth(context, 200),
              height: AppLayout.scaleWidth(context, 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: AppLayout.scaleWidth(context, 28),
                    color: Colors.grey[400],
                  ),
                  // Corner brackets
                  Positioned(
                    top: 30,
                    left: 30,
                    child: _buildCornerBracket(isTopLeft: true),
                  ),
                  Positioned(
                    top: 30,
                    right: 30,
                    child: _buildCornerBracket(isTopRight: true),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 30,
                    child: _buildCornerBracket(isBottomLeft: true),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: _buildCornerBracket(isBottomRight: true),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 40)),
            // Instructions Box
            Container(
              padding: AppLayout.pagePadding(context),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 12))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please ensure the following',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _buildInstruction('Ensure your face is well-lit'),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildInstruction(
                      'Your entire face is clearly visible within the frame'),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildInstruction(
                      'Take off glasses, hats, masks, or anything covering your face'),
                ],
              ),
            ),
            const Spacer(),
            // Next Button
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleWidth(context, 50),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelfieCaptureScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 28)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[600]!,
            width: 4,
          ),
          left: BorderSide(
            color: isTopLeft || isBottomLeft
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: isTopRight || isBottomRight
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(
            color: isBottomLeft || isBottomRight
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
