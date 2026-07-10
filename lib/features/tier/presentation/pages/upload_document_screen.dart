import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'dart:io';

import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/presentation/tier/upgrade_success_screen.dart';

class UploadDocumentScreen extends StatefulWidget {
  final UpgradeTier tier;

  const UploadDocumentScreen({super.key, required this.tier});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  String _selectedDocumentType = 'Utility Bill';
  File? _uploadedFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _documentTypes = [
    'Utility Bill',
    'Bank Statement',
    'ID Card',
    'Passport',
    'Driver\'s License',
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _uploadedFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _uploadedFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: const Color(0xFF069494),
                    size: AppLayout.scaleWidth(context, 24),
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.w600,
                      fontSize: AppLayout.fontSize(context, 16),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: const Color(0xFF069494),
                    size: AppLayout.scaleWidth(context, 24),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.w600,
                      fontSize: AppLayout.fontSize(context, 16),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitDocument() {
    if (_uploadedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document')),
      );
      return;
    }

    // Show success and navigate
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UpgradeSuccessScreen(tier: widget.tier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload a valid ID card',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kindly select the document you want to upload',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Document Type Selector
            Text(
              'Select document type',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedDocumentType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 16),
                  color: Colors.black,
                ),
                items: _documentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDocumentType = value;
                    });
                  }
                },
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Upload Document Section
            Text(
              'Upload Document',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Upload Area
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: AppLayout.scaleHeight(context, 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _uploadedFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 14)),
                            child: Image.file(
                              _uploadedFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: AppLayout.scaleHeight(context, 8),
                            right: AppLayout.scaleWidth(context, 8),
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: AppLayout.scaleWidth(context, 20),
                              ),
                              onPressed: () {
                                setState(() {
                                  _uploadedFile = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.all(
                                    AppLayout.scaleWidth(context, 8)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: AppLayout.scaleWidth(context, 48),
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 12)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 20),
                              vertical: AppLayout.scaleHeight(context, 10),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(
                                  AppLayout.scaleWidth(context, 20)),
                            ),
                            child: Text(
                              'Upload Document',
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF069494),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Helper Text
            if (_uploadedFile == null)
              Text(
                'Tap to take a photo or select from gallery',
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 12),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
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
            onPressed: _uploadedFile != null ? _submitDocument : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF069494),
              disabledBackgroundColor: Colors.grey[300],
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
              'Submit',
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
