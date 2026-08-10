// lib/features/auth/domain/usecases/auth_usecases.dart
//
// One file for all auth use-cases — each is a tiny callable class.
// Use-cases contain ONLY orchestration logic; no HTTP, no storage.
//
// Usage:
//   final user = await ref.read(loginUseCaseProvider).call(
//     identifier: email, passcode: password);

// ─────────────────────────────────────────────────────────────────────────────
// CheckAuthUseCase
// Called on app start to restore session.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';
import 'package:kudipay/features/auth/domain/repositories/auth_repositories.dart';

class CheckAuthUseCase {
  final AuthRepository _repository;
  const CheckAuthUseCase(this._repository);

  Future<UserEntity?> call() => _repository.checkAuthStatus();
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginUseCase
// ─────────────────────────────────────────────────────────────────────────────

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<UserEntity> call({
    required String identifier,
    required String passcode,
  }) =>
      _repository.login(identifier: identifier, passcode: passcode);
}

// ─────────────────────────────────────────────────────────────────────────────
// SendSignupOtpUseCase
// Step 1 of registration — sends OTP, returns otpId.
// ─────────────────────────────────────────────────────────────────────────────

class SendSignupOtpUseCase {
  final AuthRepository _repository;
  const SendSignupOtpUseCase(this._repository);

  Future<String> call({
    required String email,
    required String phoneNumber,
  }) =>
      _repository.sendSignupOtp(email: email, phoneNumber: phoneNumber);
}

// ─────────────────────────────────────────────────────────────────────────────
// ResendOtpUseCase
// ─────────────────────────────────────────────────────────────────────────────

class ResendOtpUseCase {
  final AuthRepository _repository;
  const ResendOtpUseCase(this._repository);

  Future<String> call({
    required String email,
    required String phoneNumber,
  }) =>
      _repository.resendOtp(email: email, phoneNumber: phoneNumber);
}

// ─────────────────────────────────────────────────────────────────────────────
// VerifyOtpAndRegisterUseCase
// Steps 2 + 3 of registration.
// ─────────────────────────────────────────────────────────────────────────────

class VerifyOtpAndRegisterUseCase {
  final AuthRepository _repository;
  const VerifyOtpAndRegisterUseCase(this._repository);

  Future<UserEntity> call({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
    String? referralCode,
  }) =>
      _repository.verifyOtpAndRegister(
        otpId: otpId,
        otp: otp,
        email: email,
        phoneNumber: phoneNumber,
        passcode: passcode,
        confirmPasscode: confirmPasscode,
        referralCode: referralCode,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CompleteOnboardingUseCase
// ─────────────────────────────────────────────────────────────────────────────

class SelectTierUseCase {
  final AuthRepository _repository;
  const SelectTierUseCase(this._repository);

  Future<UserEntity> call({required int tierNumber}) =>
      _repository.selectTier(tierNumber: tierNumber);
}

// ─────────────────────────────────────────────────────────────────────────────
// UpdateUserUseCase
// ─────────────────────────────────────────────────────────────────────────────

class UpdateUserUseCase {
  final AuthRepository _repository;
  const UpdateUserUseCase(this._repository);

  Future<void> call(UserEntity user) => _repository.updateUser(user);
}

// ─────────────────────────────────────────────────────────────────────────────
// LogoutUseCase
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Forgot-passcode — three ordered steps
// ─────────────────────────────────────────────────────────────────────────────

class SendForgotPasscodeOtpUseCase {
  final AuthRepository _repository;
  const SendForgotPasscodeOtpUseCase(this._repository);

  Future<String> call({required String identifier}) =>
      _repository.sendForgotPasscodeOtp(identifier: identifier);
}

class VerifyForgotPasscodeOtpUseCase {
  final AuthRepository _repository;
  const VerifyForgotPasscodeOtpUseCase(this._repository);

  Future<void> call({required String otpReference, required String code}) =>
      _repository.verifyForgotPasscodeOtp(
        otpReference: otpReference,
        code: code,
      );
}

class ResetPasscodeUseCase {
  final AuthRepository _repository;
  const ResetPasscodeUseCase(this._repository);

  Future<void> call({
    required String otpReference,
    required String newPasscode,
    required String confirmPasscode,
  }) =>
      _repository.resetPasscode(
        otpReference: otpReference,
        newPasscode: newPasscode,
        confirmPasscode: confirmPasscode,
      );
}

class LogoutUseCase {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}

// ─────────────────────────────────────────────────────────────────────────────
// LogoutAllUseCase
// ─────────────────────────────────────────────────────────────────────────────

class LogoutAllUseCase {
  final AuthRepository _repository;
  const LogoutAllUseCase(this._repository);

  Future<void> call() => _repository.logoutAll();
}
