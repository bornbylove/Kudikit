// lib/features/auth/data/models/user_model.dart
//
// Data model — knows about JSON serialization.
// Adds fromEntity() and toEntity() to bridge domain ↔ data.
// The rest of the app NEVER imports this directly — only the repository does.

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';

class UserModel {
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

  const UserModel({
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

  // ── Domain bridge ──────────────────────────────────────────────────────────

  UserEntity toEntity() => UserEntity(
        userId: userId,
        email: email,
        phoneNumber: phoneNumber,
        name: name,
        bvn: bvn,
        nin: nin,
        isEmailVerified: isEmailVerified,
        isPhoneVerified: isPhoneVerified,
        isBvnVerified: isBvnVerified,
        isAddressVerified: isAddressVerified,
        isSelfieVerified: isSelfieVerified,
        isDocumentVerified: isDocumentVerified,
        selectedTier: selectedTier,
        createdAt: createdAt,
        lastLogin: lastLogin,
      );

  factory UserModel.fromEntity(UserEntity e) => UserModel(
        userId: e.userId,
        email: e.email,
        phoneNumber: e.phoneNumber,
        name: e.name,
        bvn: e.bvn,
        nin: e.nin,
        isEmailVerified: e.isEmailVerified,
        isPhoneVerified: e.isPhoneVerified,
        isBvnVerified: e.isBvnVerified,
        isAddressVerified: e.isAddressVerified,
        isSelfieVerified: e.isSelfieVerified,
        isDocumentVerified: e.isDocumentVerified,
        selectedTier: e.selectedTier,
        createdAt: e.createdAt,
        lastLogin: e.lastLogin,
      );

  // ── JSON ───────────────────────────────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'] as String,
        email: json['email'] as String,
        phoneNumber: json['phoneNumber'] as String,
        name: json['name'] as String?,
        bvn: json['bvn'] as String?,
        nin: json['nin'] as String?,
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
        isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
        isBvnVerified: json['isBvnVerified'] as bool? ?? false,
        isAddressVerified: json['isAddressVerified'] as bool? ?? false,
        isSelfieVerified: json['isSelfieVerified'] as bool? ?? false,
        isDocumentVerified: json['isDocumentVerified'] as bool? ?? false,
        selectedTier:
            (json['selectedTier'] as int?) ?? (json['tier'] as int?) ?? 1,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'phoneNumber': phoneNumber,
        'name': name,
        'bvn': bvn,
        'nin': nin,
        'isEmailVerified': isEmailVerified,
        'isPhoneVerified': isPhoneVerified,
        'isBvnVerified': isBvnVerified,
        'isAddressVerified': isAddressVerified,
        'isSelfieVerified': isSelfieVerified,
        'isDocumentVerified': isDocumentVerified,
        'selectedTier': selectedTier,
        'createdAt': createdAt?.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };

  UserModel copyWith({
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
  }) =>
      UserModel(
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
