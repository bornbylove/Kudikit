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

  const AddressEntity({
    this.state,
    this.city,
    this.lga,
    this.landmark,
    this.streetName,
    this.houseNumber,
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
  }) =>
      AddressEntity(
        state: state ?? this.state,
        city: city ?? this.city,
        lga: lga ?? this.lga,
        landmark: landmark ?? this.landmark,
        streetName: streetName ?? this.streetName,
        houseNumber: houseNumber ?? this.houseNumber,
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
