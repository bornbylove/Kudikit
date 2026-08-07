// lib/features/auth/domain/repositories/auth_repository.dart
//
// Abstract contract that the data layer must fulfil.
// Nothing in domain or presentation imports from data/ directly —
// they only ever depend on this interface.

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';

abstract interface class AuthRepository {
  /// Checks storage for a saved token + user and validates with the server.
  /// Returns the authenticated user or null if no valid session exists.
  Future<UserEntity?> checkAuthStatus();

  /// Authenticates with [identifier] (email or phone) and [passcode].
  /// Returns the authenticated [UserEntity] on success.
  Future<UserEntity> login({
    required String identifier,
    required String passcode,
  });

  /// Sends a one-time password to [email] / [phoneNumber].
  /// Returns the otpId to pass to [verifyOtpAndRegister].
  Future<String> sendSignupOtp({
    required String email,
    required String phoneNumber,
  });

  /// Resends OTP — returns the new otpId.
  Future<String> resendOtp({
    required String email,
    required String phoneNumber,
  });

  /// Verifies [otp] then registers the account.
  /// Returns the new [UserEntity] (token may not be present until login).
  Future<UserEntity> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
  });

  /// Marks onboarding complete for the authenticated user.
  Future<void> completeOnboarding({required int tierNumber});

  /// Persists [user] changes locally (e.g. after KYC updates).
  Future<void> updateUser(UserEntity user);

  /// Clears all local session data and calls the logout endpoint.
  Future<void> logout();

  /// Revokes every active session for the user and clears local session data.
  Future<void> logoutAll();
}
