import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/usecases/selfie_state.dart';
import 'package:kudipay/presentation/address/address_notifier.dart';
import 'package:kudipay/presentation/selfie/selfie_notifier.dart';
import 'package:flutter_riverpod/legacy.dart';
/// ==================== KYC VERIFICATION PROVIDERS ====================
/// 
/// This file contains all KYC (Know Your Customer) related state providers:
/// - Selfie verification
/// - Address verification
/// - Document upload
/// - User information

// ==================== SELFIE VERIFICATION ====================

/// Provider for selfie capture and verification state
final selfieStateProvider =
    StateNotifierProvider<SelfieNotifier, SelfieState>((ref) {
  return SelfieNotifier();
});

// ==================== ADDRESS VERIFICATION ====================

/// Provider for address verification state
final addressProvider = StateNotifierProvider<AddressNotifier, AddressData>(
  (ref) => AddressNotifier(),
);

/// Selected Nigerian state for address
final selectedStateProvider = StateProvider<String?>((ref) => null);

/// Provides list of LGAs (Local Government Areas) based on selected state
final availableLgasProvider = Provider<List<String>>((ref) {
  final selectedState = ref.watch(selectedStateProvider);
  if (selectedState == null) return [];

  final location = nigeriaLocations.firstWhere(
    (loc) => loc.state == selectedState,
    orElse: () => NigeriaLocation(state: "", lgas: []),
  );

  return location.lgas;
});

// ==================== DOCUMENT UPLOAD ====================

/// Provider for document upload state and management
final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadData>(
  (ref) => DocumentUploadNotifier(),
);

/// State notifier for managing document uploads
class DocumentUploadNotifier extends StateNotifier<DocumentUploadData> {
  DocumentUploadNotifier() : super(DocumentUploadData());

  /// Sets the type of document being uploaded
  void setDocumentType(DocumentType type) {
    state = state.copyWith(documentType: type);
  }

  /// Sets the front-side image of the document
  void setFrontImage(File file, String fileName) {
    state = state.copyWith(
      frontImage: file,
      frontImageName: fileName,
      uploadProgress: 1.0,
    );
  }

  /// Sets the back-side image of the document (required for two-sided docs)
  void setBackImage(File file, String fileName) {
    state = state.copyWith(
      backImage: file,
      backImageName: fileName,
      uploadProgress: 1.0,
    );
  }

  /// Updates the upload progress (0.0 to 1.0)
  void updateProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  /// Resets the upload state
  void reset() {
    state = DocumentUploadData();
  }
}

// ==================== USER INFORMATION ====================

/// Provider for user's additional information during KYC
final userInfoProvider = StateProvider<UserInfo?>((ref) => null);