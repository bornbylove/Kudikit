// lib/features/auth/domain/entities/login_result.dart
//
// Login has two valid outcomes, not one.
//
// Since the backend added device verification, POST /auth/login can return a
// 200 carrying `deviceVerificationRequired: true` and an otpReference instead
// of tokens. That is a normal outcome, not an error — modelling it as an
// exception would put it next to genuine failures and lose the otpReference
// the next step needs.

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';

sealed class LoginResult {
  const LoginResult();
}

/// Credentials accepted and the device is already trusted — tokens issued.
class LoginSuccess extends LoginResult {
  final UserEntity user;
  const LoginSuccess(this.user);
}

/// Credentials accepted but the device is unrecognised. An OTP has been sent;
/// the flow continues via verify-otp (purpose DEVICE_LINK) then
/// POST /auth/login/verify-device.
class LoginNeedsDeviceVerification extends LoginResult {
  final String otpReference;

  /// e.g. "a***@gmail.com" — safe to show, so the user knows where to look.
  final String? maskedIdentifier;
  final int? expiresInSeconds;

  const LoginNeedsDeviceVerification({
    required this.otpReference,
    this.maskedIdentifier,
    this.expiresInSeconds,
  });
}
