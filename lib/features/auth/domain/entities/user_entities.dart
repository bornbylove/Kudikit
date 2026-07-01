// lib/features/auth/domain/entities/user_entity.dart
//
// Pure domain entity — no Flutter, no JSON, no package imports.
// This is what the rest of the app works with. Data layer converts
// UserModel → UserEntity at the repository boundary.

class UserEntity {
  final String userId;
  final String email;
  final String phoneNumber;
  final String? name;
  final String? bvn;
  final String? nin;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBvnVerified;
  final bool isAddressVerified;
  final bool isSelfieVerified;
  final bool isDocumentVerified;
  final int selectedTier;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.phoneNumber,
    this.name,
    this.bvn,
    this.nin,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isBvnVerified = false,
    this.isAddressVerified = false,
    this.isSelfieVerified = false,
    this.isDocumentVerified = false,
    this.selectedTier = 1,
    this.createdAt,
    this.lastLogin,
  });

  bool get isKycComplete =>
      isEmailVerified &&
      isBvnVerified &&
      isAddressVerified &&
      isSelfieVerified &&
      isDocumentVerified;

  double get kycProgress {
    int completed = 0;
    if (isEmailVerified) completed++;
    if (isBvnVerified) completed++;
    if (isAddressVerified) completed++;
    if (isSelfieVerified) completed++;
    if (isDocumentVerified) completed++;
    return completed / 5.0;
  }

  UserEntity copyWith({
    String? userId,
    String? email,
    String? phoneNumber,
    String? name,
    String? bvn,
    String? nin,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
    int? selectedTier,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      bvn: bvn ?? this.bvn,
      nin: nin ?? this.nin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isBvnVerified: isBvnVerified ?? this.isBvnVerified,
      isAddressVerified: isAddressVerified ?? this.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? this.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? this.isDocumentVerified,
      selectedTier: selectedTier ?? this.selectedTier,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
