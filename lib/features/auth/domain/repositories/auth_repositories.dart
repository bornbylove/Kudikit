// lib/features/auth/domain/repositories/auth_repository.dart
//
// Abstract contract that the data layer must fulfil.
// Nothing in domain or presentation imports from data/ directly —
// they only ever depend on this interface.

import 'package:kudipay/features/auth/domain/entities/login_result.dart';
import 'package:kudipay/features/auth/domain/entities/user_entities.dart';

abstract interface class AuthRepository {
  /// Checks storage for a saved token + user and validates with the server.
  /// Returns the authenticated user or null if no valid session exists.
  Future<UserEntity?> checkAuthStatus();

  /// Authenticates with [identifier] (email or phone) and [passcode].
  ///
  /// Returns [LoginSuccess] when the device is already trusted, or
  /// [LoginNeedsDeviceVerification] when the backend wants this install
  /// verified first. The device fingerprint is supplied by the data layer.
  Future<LoginResult> login({
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
  /// [referralCode] must be supplied here — RegisterRequest is the only place
  /// in the API that accepts one, so it cannot be attached after registration.
  Future<UserEntity> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
    String? referralCode,
  });

  /// Requests [tierNumber] (1 Basic, 2 Pro, 3 Mega) for the authenticated user.
  ///
  /// Returns the server's updated user. The granted tier may differ from the
  /// one requested — the backend tracks a separate `pendingTier` while KYC is
  /// outstanding — so callers should use the returned value rather than
  /// assuming the request was granted.
  Future<UserEntity> selectTier({required int tierNumber});

  /// Persists [user] changes locally (e.g. after KYC updates).
  Future<void> updateUser(UserEntity user);

  /// Starts a passcode reset for [identifier] (email or phone).
  /// Returns the otpReference to carry through the remaining two steps.
  Future<String> sendForgotPasscodeOtp({required String identifier});

  /// Verifies the reset code. Must succeed before [resetPasscode] is called —
  /// the reset endpoint takes no code of its own.
  Future<void> verifyForgotPasscodeOtp({
    required String otpReference,
    required String code,
  });

  /// Sets a new passcode against a verified [otpReference].
  Future<void> resetPasscode({
    required String otpReference,
    required String newPasscode,
    required String confirmPasscode,
  });

  /// Clears all local session data and calls the logout endpoint.
  Future<void> logout();

  /// Revokes every active session for the user and clears local session data.
  Future<void> logoutAll();
}
