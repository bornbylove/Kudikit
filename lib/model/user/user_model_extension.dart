// lib/model/user/user_model_extensions.dart
//
// Bridge extension — adds domain conversion to the old UserModel
// without modifying the class itself.
// Delete once StorageService is migrated to use UserEntity directly.

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';
import 'package:kudipay/model/user/user_model.dart';

extension UserModelX on UserModel {
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

  static UserModel fromEntity(UserEntity e) => UserModel(
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
}
