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

  /// Submits the user's residential address with proof of address.
  ///
  /// [utilityBill] is required by the endpoint — an address cannot be
  /// submitted without it.
  Future<KycStatusEntity> submitAddress(
    AddressEntity address, {
    required File utilityBill,
  });

  /// Submits a government ID document and returns the updated KYC state.
  ///
  /// [backImage] is optional — a passport has only one side. [documentType]
  /// must be one of `kIdDocumentTypes`; a utility bill is proof of address and
  /// belongs to [submitAddress] instead.
  Future<KycStatusEntity> uploadDocument({
    required File frontImage,
    File? backImage,
    required DocumentType documentType,
  });
}
