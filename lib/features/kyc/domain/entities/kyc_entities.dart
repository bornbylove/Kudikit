// lib/features/kyc/domain/entities/kyc_entities.dart
//
// All KYC domain entities in one file — pure Dart, no imports from
// Flutter, Dio, or any package. The data layer converts to/from these.

// =============================================================================
// VerificationStatus
// =============================================================================

enum VerificationStatus { idle, input, loading, success, error }

// =============================================================================
// IdType
// =============================================================================

enum IdType { bvn, nin }

extension IdTypeX on IdType {
  String get label {
    switch (this) {
      case IdType.bvn:
        return 'BVN';
      case IdType.nin:
        return 'NIN';
    }
  }

  String get hint {
    switch (this) {
      case IdType.bvn:
        return 'Enter your 11-digit BVN';
      case IdType.nin:
        return 'Enter your 11-digit NIN';
    }
  }
}

// =============================================================================
// VerifiedIdentityEntity
// Returned after a successful BVN/NIN lookup.
// =============================================================================

class VerifiedIdentityEntity {
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String? photoUrl;
  final String gender;
  final String idNumber;
  final IdType idType;

  const VerifiedIdentityEntity({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.photoUrl,
    required this.gender,
    required this.idNumber,
    required this.idType,
  });

  String get displayName => fullName.isNotEmpty
      ? fullName
      : '$firstName $middleName $lastName'.trim();
}

// =============================================================================
// AddressEntity
// =============================================================================

class AddressEntity {
  final String? state;
  final String? city;
  final String? lga;
  final String? landmark;
  final String? streetName;
  final String? houseNumber;

  /// Optional neighbourhood/estate. Accepted by verify-address but not yet
  /// collected by the address form.
  final String? area;

  const AddressEntity({
    this.state,
    this.city,
    this.lga,
    this.landmark,
    this.streetName,
    this.houseNumber,
    this.area,
  });

  bool get isComplete =>
      state != null &&
      city != null &&
      lga != null &&
      landmark != null &&
      streetName != null &&
      houseNumber != null;

  AddressEntity copyWith({
    String? state,
    String? city,
    String? lga,
    String? landmark,
    String? streetName,
    String? houseNumber,
    String? area,
  }) =>
      AddressEntity(
        state: state ?? this.state,
        city: city ?? this.city,
        lga: lga ?? this.lga,
        landmark: landmark ?? this.landmark,
        streetName: streetName ?? this.streetName,
        houseNumber: houseNumber ?? this.houseNumber,
        area: area ?? this.area,
      );
}

// =============================================================================
// SelfieEntity
// =============================================================================

class SelfieEntity {
  final String imagePath;
  final bool validationPassed;

  const SelfieEntity({
    required this.imagePath,
    required this.validationPassed,
  });
}

// =============================================================================
// KycStatusEntity
// Server-side KYC state from GET /auth/kyc/status. This is the source of truth
// for verification flags — UserModel's isXVerified booleans are only a local
// cache and can drift.
// =============================================================================

enum KycOverallStatus {
  notStarted,
  pending,
  inProgress,
  manualReview,
  verified,
  rejected,
  expired,
}

enum KycDocumentStatus { notStarted, verified, rejected, manualReview }

enum KycAddressStatus { notStarted, pendingAgentVisit, verified, rejected }

class KycStatusEntity {
  final KycOverallStatus overall;
  final bool bvnVerified;
  final bool ninVerified;

  /// Liveness/selfie check. Submitted as part of BVN/NIN verification rather
  /// than as its own step.
  final bool livenessVerified;

  final KycDocumentStatus documentStatus;
  final KycAddressStatus addressStatus;
  final bool requiresManualReview;
  final String? rejectionReason;

  /// Legal name as returned by the BVN/NIN bureau.
  final String? bvnFullName;
  final String? ninFullName;

  /// Date of birth as returned by the BVN/NIN bureau.
  final DateTime? bvnDateOfBirth;
  final DateTime? ninDateOfBirth;

  const KycStatusEntity({
    this.overall = KycOverallStatus.notStarted,
    this.bvnVerified = false,
    this.ninVerified = false,
    this.livenessVerified = false,
    this.documentStatus = KycDocumentStatus.notStarted,
    this.addressStatus = KycAddressStatus.notStarted,
    this.requiresManualReview = false,
    this.rejectionReason,
    this.bvnFullName,
    this.ninFullName,
    this.bvnDateOfBirth,
    this.ninDateOfBirth,
  });

  bool get documentVerified => documentStatus == KycDocumentStatus.verified;
  bool get addressVerified => addressStatus == KycAddressStatus.verified;
  bool get isComplete => overall == KycOverallStatus.verified;

  /// Whichever bureau-confirmed name is available. This is the only
  /// authoritative source of the user's legal name.
  String? get verifiedFullName => bvnFullName ?? ninFullName;

  /// Whichever bureau-confirmed date of birth is available.
  DateTime? get verifiedDateOfBirth => bvnDateOfBirth ?? ninDateOfBirth;
}
