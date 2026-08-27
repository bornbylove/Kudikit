import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';
import 'package:kudipay/presentation/address/address_notifier.dart';
import 'package:kudipay/presentation/selfie/selfie_notifier.dart';
import 'package:kudipay/usecases/selfie_state.dart';
import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
// ==================== SELFIE PROVIDER ====================

final selfieStateProvider =
    StateNotifierProvider<SelfieNotifier, SelfieState>((ref) {
  return SelfieNotifier();
});

// ==================== ADDRESS PROVIDERS ====================

final addressProvider = StateNotifierProvider<AddressNotifier, AddressData>(
  (ref) => AddressNotifier(),
);

final selectedStateProvider = StateProvider<String?>((ref) => null);

final availableLgasProvider = Provider<List<String>>((ref) {
  final selectedState = ref.watch(selectedStateProvider);
  if (selectedState == null) return [];

  final location = nigeriaLocations.firstWhere(
    (loc) => loc.state == selectedState,
    orElse: () => NigeriaLocation(state: "", lgas: []),
  );

  return location.lgas;
});

// ==================== DOCUMENT UPLOAD PROVIDER ====================

final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadData>(
  (ref) => DocumentUploadNotifier(),
);

class DocumentUploadNotifier extends StateNotifier<DocumentUploadData> {
  DocumentUploadNotifier() : super(DocumentUploadData());

  void setDocumentType(DocumentType type) {
    state = state.copyWith(documentType: type);
  }

  void setFrontImage(File file, String fileName) {
    state = state.copyWith(
      frontImage: file,
      frontImageName: fileName,
      uploadProgress: 1.0,
    );
  }

  void setBackImage(File file, String fileName) {
    state = state.copyWith(
      backImage: file,
      backImageName: fileName,
      uploadProgress: 1.0,
    );
  }

  void updateProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  void reset() {
    state = DocumentUploadData();
  }
}
