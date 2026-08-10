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

import 'package:kudipay/features/identity/domain/entities/document_data.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// verify-id-document
//
//   POST /auth/kyc/verify-id-document
//   { documentType*, frontImageBase64*, backImageBase64? }
// ─────────────────────────────────────────────────────────────────────────────

const String kVerifyIdDocumentPath = '/auth/kyc/verify-id-document';

/// The four document types the backend accepts as proof of identity.
///
/// [DocumentType] also carries `utilityBill`, which is NOT one of these — a
/// utility bill is proof of *address* and goes to verify-address as
/// `utilityBillImageBase64`. Use this list to populate any ID-document picker.
const List<DocumentType> kIdDocumentTypes = [
  DocumentType.passport,
  DocumentType.driversLicense,
  DocumentType.nationalId,
  DocumentType.votersCard,
];

/// Wire value for the server's `documentType` enum, or null when [type] is not
/// a valid ID document.
String? idDocumentTypeWire(DocumentType type) {
  switch (type) {
    case DocumentType.passport:
      return 'PASSPORT';
    case DocumentType.driversLicense:
      return 'DRIVERS_LICENSE';
    case DocumentType.nationalId:
      return 'NATIONAL_ID';
    case DocumentType.votersCard:
      return 'VOTERS_CARD';
    case DocumentType.utilityBill:
      // Proof of address, not identity — see kIdDocumentTypes.
      return null;
  }
}

/// [backImageBase64] is omitted entirely when null rather than sent as null,
/// since the field is optional and a passport has only one side.
Map<String, dynamic> buildVerifyIdDocumentBody({
  required String documentTypeWire,
  required String frontImageBase64,
  String? backImageBase64,
}) {
  return {
    'documentType': documentTypeWire,
    'frontImageBase64': frontImageBase64,
    if (backImageBase64 != null) 'backImageBase64': backImageBase64,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// verify-address
//
//   POST /auth/kyc/verify-address
//   required: city, houseNumber, lga, state, street, utilityBillImageBase64
//   optional: landmark, area
// ─────────────────────────────────────────────────────────────────────────────

const String kVerifyAddressPath = '/auth/kyc/verify-address';

/// Longest value the server accepts for each address text field.
const int kAddressFieldMaxLength = 100;

/// The required text fields are declared `minLength: 0`, so the server wants
/// the keys *present* even when empty — only `utilityBillImageBase64` has a
/// non-zero minimum. They are therefore always emitted, while the two genuinely
/// optional fields are omitted when blank.
Map<String, dynamic> buildVerifyAddressBody({
  required String houseNumber,
  required String street,
  required String lga,
  required String city,
  required String state,
  required String utilityBillImageBase64,
  String? landmark,
  String? area,
}) {
  return {
    'houseNumber': houseNumber,
    'street': street,
    'lga': lga,
    'city': city,
    'state': state,
    'utilityBillImageBase64': utilityBillImageBase64,
    if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
    if (area != null && area.isNotEmpty) 'area': area,
  };
}
