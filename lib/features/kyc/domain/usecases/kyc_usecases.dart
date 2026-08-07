// lib/features/kyc/domain/usecases/kyc_usecases.dart

import 'dart:io';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';
import 'package:kudipay/features/kyc/domain/repositories/kyc_repositories.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';

class GetKycStatusUseCase {
  final KycRepository _repository;
  const GetKycStatusUseCase(this._repository);

  Future<KycStatusEntity> call() => _repository.getKycStatus();
}

/// Verifies BVN/NIN and liveness in a single call. See [KycRepository].
class VerifyIdentityUseCase {
  final KycRepository _repository;
  const VerifyIdentityUseCase(this._repository);

  Future<KycStatusEntity> call({
    required String idNumber,
    required IdType idType,
    required File selfieImage,
  }) =>
      _repository.verifyIdentity(
        idNumber: idNumber,
        idType: idType,
        selfieImage: selfieImage,
      );
}

class SubmitAddressUseCase {
  final KycRepository _repository;
  const SubmitAddressUseCase(this._repository);

  Future<void> call(AddressEntity address) =>
      _repository.submitAddress(address);
}

class UploadDocumentUseCase {
  final KycRepository _repository;
  const UploadDocumentUseCase(this._repository);

  Future<void> call({
    required File file,
    required DocumentType documentType,
  }) =>
      _repository.uploadDocument(file: file, documentType: documentType);
}
