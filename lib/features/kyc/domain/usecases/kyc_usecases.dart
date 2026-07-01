// lib/features/kyc/domain/usecases/kyc_usecases.dart

import 'dart:io';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';
import 'package:kudipay/features/kyc/domain/repositories/kyc_repositories.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';

class VerifyIdentityUseCase {
  final KycRepository _repository;
  const VerifyIdentityUseCase(this._repository);

  Future<VerifiedIdentityEntity> call({
    required String idNumber,
    required IdType idType,
  }) =>
      _repository.verifyIdentity(idNumber: idNumber, idType: idType);
}

class ConfirmIdentityUseCase {
  final KycRepository _repository;
  const ConfirmIdentityUseCase(this._repository);

  Future<void> call(VerifiedIdentityEntity identity) =>
      _repository.confirmIdentity(identity: identity);
}

class SubmitAddressUseCase {
  final KycRepository _repository;
  const SubmitAddressUseCase(this._repository);

  Future<void> call(AddressEntity address) =>
      _repository.submitAddress(address);
}

class UploadSelfieUseCase {
  final KycRepository _repository;
  const UploadSelfieUseCase(this._repository);

  Future<SelfieEntity> call(File imageFile) =>
      _repository.uploadSelfie(imageFile);
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
