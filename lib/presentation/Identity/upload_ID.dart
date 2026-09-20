import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/utils/image_base64_util.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/presentation/Identity/confirm_info.dart';
import 'package:kudipay/presentation/kyc/kyc_next_step.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/kyc/kyc_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';
import 'dart:io';

class UploadIdCardScreen extends ConsumerWidget {
  const UploadIdCardScreen({Key? key}) : super(key: key);

  Future<void> _pickFrontImage(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        ref
            .read(documentUploadProvider.notifier)
            .setFrontImage(
                File(result.files.single.path!), result.files.single.name);
      }
    } catch (e) {
      debugPrint('Error picking front image: $e');
    }
  }

  Future<void> _pickBackImage(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        ref
            .read(documentUploadProvider.notifier)
            .setBackImage(
                File(result.files.single.path!), result.files.single.name);
      }
    } catch (e) {
      debugPrint('Error picking back image: $e');
    }
  }

  Future<void> _submitDocument(
      BuildContext context, WidgetRef ref, DocumentUploadData data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF069494)),
      ),
    );

    try {
      final frontBase64 = await ImageBase64Util.encodeToBase64(
          XFile(data.frontImage!.path));
      String? backBase64;
      if (data.backRequired) {
        backBase64 = await ImageBase64Util.encodeToBase64(
            XFile(data.backImage!.path));
      }

      // Slice 5: real submission to POST /auth/kyc/verify-id-document. The
      // authoritative idDocumentStatus comes from the server and is applied
      // to the UserModel (MANUAL_REVIEW is preserved, never collapsed into a
      // boolean). A 400 REJECTION is reconciled server-side before rethrowing.
      await ref.read(authProvider.notifier).verifyIdDocument(
            documentType: data.documentType!.backendValue,
            frontImageBase64: frontBase64,
            backImageBase64: backBase64,
          );

      if (context.mounted) Navigator.pop(context);

      final storageService = ref.read(storageServiceProvider);
      UserInfo? userInfo = await storageService.getUserInfo();

      // FIX: was ref.read(currentUserProvider) fetched BEFORE the await above
      // in the original code — re-read now so isDocumentVerified reflects the
      // verifyIdDocument() call that just completed (applyKyc already updated
      // the cached UserModel by this point).
      final currentUser = ref.read(currentUserProvider);

      if (userInfo == null && currentUser != null) {
        userInfo = UserInfo(
          firstName: currentUser.name?.split(' ').first ?? '',
          lastName: currentUser.name?.split(' ').last ?? '',
          bvn: currentUser.bvn ?? '',
          nin: currentUser.nin ?? '',
          dateOfBirth: DateTime(1990, 1, 1),
        );
      }

      if (context.mounted && userInfo != null && currentUser != null) {
        // FIX: this used to always go to ConfirmInfoScreen next, even for
        // Mega — which still needs address verification after ID doc. Route
        // through the same tier-aware "what's next" logic chooseID.dart uses.
        final tier =
            effectiveKycTier(currentUser, ref.read(tierProvider).currentTier);
        final nextScreen = nextIncompleteKycStep(tier, currentUser);
        // pushReplacement removes UploadIdCardScreen from the stack — the user
        // cannot go back to document upload after submitting.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                nextScreen ?? ConfirmInfoScreen(userInfo: userInfo!),
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
    } on KudiApiException catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
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

  Widget _uploadArea(
    BuildContext context,
    String title,
    String? fileName,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: AppLayout.scaleWidth(context, 40),
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
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: const Color(0xFF069494),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (fileName != null) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 10)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                child: Text(
                  fileName,
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentData = ref.watch(documentUploadProvider);
    final showBack = documentData.backRequired;

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
                          value: documentData.documentType,
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
                          items: DocumentType.values
                              .where((t) => t != DocumentType.utilityBill)
                              .map((type) {
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
                      _uploadArea(
                        context,
                        'Upload Front',
                        documentData.frontImageName,
                        () => _pickFrontImage(ref),
                      ),
                      if (showBack) ...[
                        SizedBox(height: AppLayout.scaleHeight(context, 16)),
                        _uploadArea(
                          context,
                          'Upload Back',
                          documentData.backImageName,
                          () => _pickBackImage(ref),
                        ),
                      ],
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
                        ? () => _submitDocument(context, ref, documentData)
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