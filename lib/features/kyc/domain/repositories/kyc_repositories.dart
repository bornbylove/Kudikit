// lib/features/kyc/domain/repositories/kyc_repository.dart

import 'dart:io';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';

abstract interface class KycRepository {
  /// Verifies a BVN or NIN and returns the identity data from the bureau.
  Future<VerifiedIdentityEntity> verifyIdentity({
    required String idNumber,
    required IdType idType,
  });

  /// Submits the verified identity to the backend to mark BVN/NIN as confirmed.
  Future<void> confirmIdentity({
    required VerifiedIdentityEntity identity,
  });

  /// Submits the user's residential address.
  Future<void> submitAddress(AddressEntity address);

  /// Uploads a selfie image and returns the validated [SelfieEntity].
  Future<SelfieEntity> uploadSelfie(File imageFile);

  /// Uploads a KYC document (utility bill, passport, etc.).
  Future<void> uploadDocument({
    required File file,
    required DocumentType documentType,
  });
}
