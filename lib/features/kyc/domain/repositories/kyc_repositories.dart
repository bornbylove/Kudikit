// lib/features/kyc/domain/repositories/kyc_repository.dart

import 'dart:io';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';

abstract interface class KycRepository {
  /// Fetches server-side KYC state — the source of truth for which
  /// verification steps have actually completed.
  Future<KycStatusEntity> getKycStatus();

  /// Verifies a BVN or NIN together with a liveness selfie, and returns the
  /// updated server-side KYC state.
  ///
  /// [selfieImage] is required: the backend has no standalone selfie endpoint,
  /// so identity and liveness are submitted in one call. There is likewise no
  /// separate "confirm identity" step — a successful call *is* the
  /// confirmation, reflected in the returned [KycStatusEntity].
  Future<KycStatusEntity> verifyIdentity({
    required String idNumber,
    required IdType idType,
    required File selfieImage,
  });

  /// Submits the user's residential address.
  Future<void> submitAddress(AddressEntity address);

  /// Uploads a KYC document (utility bill, passport, etc.).
  Future<void> uploadDocument({
    required File file,
    required DocumentType documentType,
  });
}
