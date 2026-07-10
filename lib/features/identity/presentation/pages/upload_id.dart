import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/features/identity/presentation/pages/confirm_info.dart';

import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/kyc/presentation/controllers/kyc_controllers.dart';
import 'dart:io';

class UploadIdCardScreen extends ConsumerWidget {
  const UploadIdCardScreen({super.key});

  Future<void> _pickDocument(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        ref
            .read(documentUploadProvider.notifier)
            .setUploadedFile(file, fileName);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentData = ref.watch(documentUploadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Upload a valid ID card',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 26),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Text(
                        'Kindly select the document you want to upload',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 32)),
                      Text(
                        'Select document type',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppLayout.scaleWidth(context, 8)),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<DocumentType>(
                          initialValue: documentData.documentType,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 16),
                              vertical: AppLayout.scaleHeight(context, 12),
                            ),
                          ),
                          hint: const Text('Select Document Type'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: DocumentType.values.map((type) {
                            return DropdownMenuItem<DocumentType>(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(documentUploadProvider.notifier)
                                  .setDocumentType(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 32)),
                      Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),
                      GestureDetector(
                        onTap: () => _pickDocument(ref),
                        child: Container(
                          width: double.infinity,
                          height: AppLayout.scaleHeight(context, 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 12)),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: AppLayout.scaleWidth(context, 48),
                                color: Colors.grey[400],
                              ),
                              SizedBox(
                                  height: AppLayout.scaleHeight(context, 16)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppLayout.scaleWidth(context, 24),
                                  vertical: AppLayout.scaleHeight(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(
                                      AppLayout.scaleWidth(context, 20)),
                                ),
                                child: Text(
                                  'Upload Document',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    color: const Color(0xFF069494),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (documentData.fileName != null) ...[
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 12)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        AppLayout.scaleWidth(context, 16),
                                  ),
                                  child: Text(
                                    documentData.fileName!,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppLayout.pagePadding(context),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: documentData.isComplete
                        ? () async {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF069494),
                                ),
                              ),
                            );

                            try {
                              // Persist document verification flag so
                              // KycFlowManager skips this step on re-entry.
                              await ref
                                  .read(authProvider.notifier)
                                  .updateKycStatus(
                                    isDocumentVerified: true,
                                  );

                              // Prefer UserInfo from storage (set during ID
                              // verification step). Fall back to building it
                              // from the current UserModel if storage returns
                              // null — this covers the case where the user
                              // resumed the flow after a fresh app launch.
                              final storageService =
                                  ref.read(storageServiceProvider);
                              UserInfo? userInfo =
                                  await storageService.getUserInfo();

                              if (userInfo == null) {
                                final currentUser =
                                    ref.read(currentUserProvider);
                                if (currentUser != null) {
                                  userInfo = UserInfo(
                                    firstName:
                                        currentUser.name?.split(' ').first ??
                                            '',
                                    lastName:
                                        currentUser.name?.split(' ').last ?? '',
                                    bvn: currentUser.bvn ?? '',
                                    dateOfBirth: DateTime(1990, 1, 1),
                                  );
                                }
                              }

                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              if (context.mounted && userInfo != null) {
                                // pushReplacement removes UploadIdCardScreen
                                // from the stack — user cannot go back to
                                // document upload after submitting.
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ConfirmInfoScreen(
                                      userInfo: userInfo!,
                                    ),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'User information not found. Please complete your profile.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              // Show error
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 30)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: documentData.isComplete
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
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
