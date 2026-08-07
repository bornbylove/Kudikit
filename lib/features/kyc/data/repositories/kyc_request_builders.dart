// lib/features/kyc/data/repositories/kyc_request_builders.dart
//
// Path selection and request-body construction for the KYC endpoints, kept as
// pure functions so the wire contract is unit-testable without a Dio fake.
//
// Verified against /v3/api-docs:
//
//   POST /auth/kyc/verify-bvn  { bvn*, selfieImageBase64* }
//   POST /auth/kyc/verify-nin  { nin*, selfieImageBase64* }
//
// Note there is no standalone selfie endpoint. The selfie is a *required*
// field on both identity calls — liveness and identity are verified together
// in a single request, which is why uploadSelfie() no longer exists.

import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

/// BVN and NIN are separate endpoints rather than one call discriminated by a
/// body field.
String kycVerifyPathFor(IdType idType) {
  switch (idType) {
    case IdType.bvn:
      return '/auth/kyc/verify-bvn';
    case IdType.nin:
      return '/auth/kyc/verify-nin';
  }
}

/// The ID number is keyed as `bvn` or `nin` depending on the endpoint — there
/// is no shared `idNumber` field.
Map<String, dynamic> buildIdentityVerificationBody({
  required String idNumber,
  required IdType idType,
  required String selfieImageBase64,
}) {
  return {
    switch (idType) {
      IdType.bvn => 'bvn',
      IdType.nin => 'nin',
    }: idNumber,
    'selfieImageBase64': selfieImageBase64,
  };
}
