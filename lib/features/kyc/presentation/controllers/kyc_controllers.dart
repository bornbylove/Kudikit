// lib/features/kyc/presentation/controllers/kyc_controllers.dart
//
// Replaces:
//   lib/provider/kyc/kyc_provider.dart
//   lib/provider/Identity_verify/identity_verify_provider.dart
//   lib/provider/selfie/selfie_provider.dart
//   lib/presentation/address/address_notifier.dart
//   lib/presentation/selfie/selfie_notifier.dart
//
// All old import paths are re-exported at the bottom as shims.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/errors/exceptions.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_repository_impl.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';
import 'package:kudipay/features/kyc/domain/repositories/kyc_repositories.dart';

import 'package:kudipay/features/kyc/domain/usecases/kyc_usecases.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';
import 'package:kudipay/model/user/user_info.dart';

// =============================================================================
// DI — repository + use-case providers
// =============================================================================

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepositoryImpl(ref.read(dioClientProvider));
});

final verifyIdentityUseCaseProvider =
    Provider((ref) => VerifyIdentityUseCase(ref.read(kycRepositoryProvider)));
final confirmIdentityUseCaseProvider =
    Provider((ref) => ConfirmIdentityUseCase(ref.read(kycRepositoryProvider)));
final submitAddressUseCaseProvider =
    Provider((ref) => SubmitAddressUseCase(ref.read(kycRepositoryProvider)));
final uploadSelfieUseCaseProvider =
    Provider((ref) => UploadSelfieUseCase(ref.read(kycRepositoryProvider)));
final uploadDocumentUseCaseProvider =
    Provider((ref) => UploadDocumentUseCase(ref.read(kycRepositoryProvider)));

// =============================================================================
// IdVerificationState + IdVerificationController
// Replaces lib/presentation/Identity/id_verification_controller.dart
// =============================================================================

class IdVerificationState {
  final IdType idType;
  final VerificationStatus status;
  final String? error;
  final Map<String, dynamic>? data;

  const IdVerificationState({
    required this.idType,
    this.status = VerificationStatus.idle,
    this.error,
    this.data,
  });

  IdVerificationState copyWith({
    IdType? idType,
    VerificationStatus? status,
    String? error,
    Map<String, dynamic>? data,
  }) =>
      IdVerificationState(
        idType: idType ?? this.idType,
        status: status ?? this.status,
        error: error,
        data: data ?? this.data,
      );
}

class IdVerificationController extends StateNotifier<IdVerificationState> {
  final VerifyIdentityUseCase _verifyIdentity;

  IdVerificationController(this._verifyIdentity)
      : super(const IdVerificationState(idType: IdType.bvn));

  void changeIdType(IdType type) {
    state = state.copyWith(
      idType: type,
      status: VerificationStatus.input,
      error: null,
      data: null,
    );
  }

  Future<void> verifyId(String idNumber) async {
    if (idNumber.length != 11) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: '${state.idType.label} must be 11 digits',
      );
      return;
    }

    state = state.copyWith(status: VerificationStatus.loading, error: null);

    try {
      final identity = await _verifyIdentity.call(
        idNumber: idNumber,
        idType: state.idType,
      );
      state = state.copyWith(
        status: VerificationStatus.success,
        data: {
          'name': identity.displayName,
          'first_name': identity.firstName,
          'last_name': identity.lastName,
          'date_of_birth': identity.dateOfBirth.toIso8601String(),
          'idType': identity.idType.label,
        },
      );
    } on KudiApiException catch (e) {
      state =
          state.copyWith(status: VerificationStatus.error, error: e.message);
    } catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  void reset() => state = IdVerificationState(idType: state.idType);
}

final idVerificationProvider =
    StateNotifierProvider<IdVerificationController, IdVerificationState>(
  (ref) => IdVerificationController(ref.read(verifyIdentityUseCaseProvider)),
);

// =============================================================================
// IdentityVerificationState + IdentityVerificationNotifier
// Replaces lib/provider/Identity_verify/identity_verify_provider.dart
// =============================================================================

class IdentityVerificationState {
  final VerifiedIdentityEntity? verificationData;
  final bool isVerifying;
  final String? error;

  const IdentityVerificationState({
    this.verificationData,
    this.isVerifying = false,
    this.error,
  });

  IdentityVerificationState copyWith({
    VerifiedIdentityEntity? verificationData,
    bool? isVerifying,
    String? error,
    bool clearError = false,
  }) =>
      IdentityVerificationState(
        verificationData: verificationData ?? this.verificationData,
        isVerifying: isVerifying ?? this.isVerifying,
        error: clearError ? null : (error ?? this.error),
      );
}

class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationState> {
  final VerifyIdentityUseCase _verifyIdentity;

  IdentityVerificationNotifier(this._verifyIdentity)
      : super(const IdentityVerificationState());

  Future<void> verifyIdentity({
    required String idNumber,
    required IdType idType,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final identity = await _verifyIdentity.call(
        idNumber: idNumber,
        idType: idType,
      );
      state = state.copyWith(isVerifying: false, verificationData: identity);
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const IdentityVerificationState();
}

final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  return IdentityVerificationNotifier(ref.read(verifyIdentityUseCaseProvider));
});

// =============================================================================
// SelfieState + SelfieNotifier
// Replaces lib/presentation/selfie/selfie_notifier.dart
// =============================================================================

class SelfieState {
  final bool isLoading;
  final String? imagePath;
  final String? error;
  final bool isCameraInitialized;
  final bool faceDetected;
  final bool validationPassed;

  const SelfieState({
    this.isLoading = false,
    this.imagePath,
    this.error,
    this.isCameraInitialized = false,
    this.faceDetected = false,
    this.validationPassed = false,
  });

  SelfieState copyWith({
    bool? isLoading,
    String? imagePath,
    String? error,
    bool? isCameraInitialized,
    bool? faceDetected,
    bool? validationPassed,
  }) =>
      SelfieState(
        isLoading: isLoading ?? this.isLoading,
        imagePath: imagePath ?? this.imagePath,
        error: error,
        isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
        faceDetected: faceDetected ?? this.faceDetected,
        validationPassed: validationPassed ?? this.validationPassed,
      );
}

class SelfieNotifier extends StateNotifier<SelfieState> {
  final UploadSelfieUseCase _uploadSelfie;

  SelfieNotifier(this._uploadSelfie) : super(const SelfieState());

  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setCameraInitialized(bool initialized) =>
      state = state.copyWith(isCameraInitialized: initialized);
  void setFaceDetected(bool detected) =>
      state = state.copyWith(faceDetected: detected);

  Future<void> validateAndUploadImage(String imagePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final selfie = await _uploadSelfie.call(File(imagePath));
      state = state.copyWith(
        isLoading: false,
        imagePath: selfie.imagePath,
        validationPassed: selfie.validationPassed,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to process image. Please try again.',
      );
    }
  }

  void reset() => state = const SelfieState();
}

final selfieStateProvider =
    StateNotifierProvider<SelfieNotifier, SelfieState>((ref) {
  return SelfieNotifier(ref.read(uploadSelfieUseCaseProvider));
});

// =============================================================================
// AddressData + AddressNotifier
// Replaces lib/presentation/address/address_notifier.dart
// Uses existing AddressData from lib/model/address/nigeria_state.dart
// =============================================================================

class AddressNotifier extends StateNotifier<AddressData> {
  AddressNotifier() : super(AddressData());

  void updateState(String value) => state = AddressData(
        state: value,
        city: state.city,
        lga: null, // reset LGA when state changes
        landmark: state.landmark,
        streetName: state.streetName,
        houseNumber: state.houseNumber,
      );

  void updateCity(String value) => state = AddressData(
        state: state.state,
        city: value,
        lga: state.lga,
        landmark: state.landmark,
        streetName: state.streetName,
        houseNumber: state.houseNumber,
      );

  void updateLga(String value) => state = AddressData(
        state: state.state,
        city: state.city,
        lga: value,
        landmark: state.landmark,
        streetName: state.streetName,
        houseNumber: state.houseNumber,
      );

  void updateLandmark(String value) => state = AddressData(
        state: state.state,
        city: state.city,
        lga: state.lga,
        landmark: value,
        streetName: state.streetName,
        houseNumber: state.houseNumber,
      );

  void updateStreetName(String value) => state = AddressData(
        state: state.state,
        city: state.city,
        lga: state.lga,
        landmark: state.landmark,
        streetName: value,
        houseNumber: state.houseNumber,
      );

  void updateHouseNumber(String value) => state = AddressData(
        state: state.state,
        city: state.city,
        lga: state.lga,
        landmark: state.landmark,
        streetName: state.streetName,
        houseNumber: value,
      );

  void reset() => state = AddressData();
}

final addressProvider = StateNotifierProvider<AddressNotifier, AddressData>(
  (ref) => AddressNotifier(),
);

final selectedStateProvider = StateProvider<String?>((ref) => null);

final availableLgasProvider = Provider<List<String>>((ref) {
  final selectedState = ref.watch(selectedStateProvider);
  if (selectedState == null) return [];
  final location = nigeriaLocations.firstWhere(
    (loc) => loc.state == selectedState,
    orElse: () => NigeriaLocation(state: '', lgas: []),
  );
  return location.lgas;
});

// =============================================================================
// DocumentUploadData + DocumentUploadNotifier
// Replaces inline notifier in kyc_provider.dart / selfie_provider.dart
// =============================================================================

// =============================================================================
// DocumentUploadData + DocumentUploadNotifier
// Uses DocumentType and DocumentUploadData from:
//   lib/model/IDdocument/document_data.dart
// =============================================================================

class DocumentUploadNotifier extends StateNotifier<DocumentUploadData> {
  DocumentUploadNotifier() : super(DocumentUploadData());

  void setDocumentType(DocumentType type) =>
      state = state.copyWith(documentType: type);

  void setUploadedFile(File file, String fileName) => state = state.copyWith(
        uploadedFile: file,
        fileName: fileName,
        uploadProgress: 1.0,
      );

  void updateProgress(double progress) =>
      state = state.copyWith(uploadProgress: progress);

  void reset() => state = DocumentUploadData();
}

final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadData>(
  (ref) => DocumentUploadNotifier(),
);

// =============================================================================
// Misc KYC providers
// =============================================================================

final userInfoProvider = StateProvider<UserInfo?>((ref) => null);
