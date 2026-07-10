import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:kudipay/features/linkdevice/presentation/pages/upload_id_screen.dart';

class VerifyIdentityScreen extends ConsumerStatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  ConsumerState<VerifyIdentityScreen> createState() =>
      _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends ConsumerState<VerifyIdentityScreen> {
  // Captured documents retained for the pending verification-submit call.
  // ignore: unused_field
  File? _idDocument;
  // ignore: unused_field
  File? _selfie;
  bool _isIdUploaded = false;
  bool _isSelfieUploaded = false;
  int _progressPercentage = 48;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickIdDocument() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idDocument = File(image.path);
        _isIdUploaded = true;
        _updateProgress();
      });
    }
  }

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selfie = File(image.path);
        _isSelfieUploaded = true;
        _updateProgress();
      });
    }
  }

  void _updateProgress() {
    int completed = 0;
    if (_isIdUploaded) completed++;
    if (_isSelfieUploaded) completed++;
    setState(() {
      _progressPercentage = 48 + (completed * 26);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      // FIX: bottomNavigationBar must be a plain widget, not Positioned.
      // Replaced with SafeArea+Column so the button is anchored at the bottom.
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
          child: Center(
            child: SizedBox(
              width: AppLayout.scaleWidth(context, 30),
              height: AppLayout.scaleWidth(context, 30),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: _progressPercentage / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF069494),
                      ),
                    ),
                  ),
                  Text(
                    '$_progressPercentage%',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
          _buildIcon(context),
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
          Text(
            'Verify your identity',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 24),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            'Since you don\'t have access to your old device, we\'ll need to confirm your identity to keep your account secure.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),
          _buildUploadCard(
            context,
            icon: Icons.upload_file,
            iconColor: const Color(0xFF5E35B1),
            title: 'Upload ID',
            subtitle: 'Driver\'s license or passport',
            isCompleted: _isIdUploaded,
            onTap: _pickIdDocument,
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildUploadCard(
            context,
            icon: Icons.camera_alt,
            iconColor: const Color(0xFF5E35B1),
            title: 'Take a selfie',
            subtitle: 'Verify it\'s really you',
            isCompleted: _isSelfieUploaded,
            onTap: _takeSelfie,
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
          _buildInfoCard(context),
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 64),
      height: AppLayout.scaleWidth(context, 64),
      decoration: const BoxDecoration(
        color: Color(0xFF5E35B1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 32),
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF4CAF50) : Colors.transparent,
            width: 2,
          ),
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
            Container(
              width: AppLayout.scaleWidth(context, 48),
              height: AppLayout.scaleWidth(context, 48),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFE8F5E9)
                    : iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? const Color(0xFF4CAF50) : iconColor,
                size: AppLayout.scaleWidth(context, 24),
              ),
            ),

            SizedBox(width: AppLayout.scaleWidth(context, 16)),

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
                    isCompleted
                        ? '${title.toLowerCase()} uploaded successfully'
                        : subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: isCompleted
                          ? const Color(0xFF4CAF50)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // FIX: added trailing arrow/check indicator for clarity
            Icon(
              isCompleted
                  ? Icons.check_circle_outline
                  : Icons.arrow_forward_ios,
              color: isCompleted ? const Color(0xFF4CAF50) : Colors.black26,
              size: AppLayout.scaleWidth(context, 18),
            ),
          ],
        ),
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
              'Your documents are encrypted and only used for verification. We\'ll delete them after review.',
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
    // FIX: was returning Positioned — invalid outside a Stack.
    // Now returns a plain Padding widget anchored at the column bottom.
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
              onPressed: (_isIdUploaded && _isSelfieUploaded)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadIdScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Start Verification',
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
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
