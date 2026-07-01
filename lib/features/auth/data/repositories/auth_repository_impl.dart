// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implements AuthRepository using AuthService (HTTP) + StorageService (local).
// This is the ONLY file that imports from both the data layer and the service
// layer simultaneously. Everything above this uses only domain types.

import 'package:flutter/foundation.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/features/auth/data/auth_services.dart';

import 'package:kudipay/features/auth/domain/entities/user_entities.dart';
import 'package:kudipay/features/auth/domain/repositories/auth_repositories.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/model/user/user_model_extension.dart';
// ADD

import 'package:kudipay/services/storage_services.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final StorageService _storage;

  const AuthRepositoryImpl({
    required AuthService authService,
    required StorageService storage,
  })  : _authService = authService,
        _storage = storage;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _extractToken(Map<String, dynamic> res) =>
      (res['accessToken'] ?? res['token']) as String?;

  bool _isSuccess(Map<String, dynamic> res) =>
      res['success'] == true ||
      res['status'] == 'success' ||
      res['statusCode'] == 201 ||
      res['statusCode'] == 200 ||
      (res['message'] as String? ?? '').toLowerCase().contains('success') ||
      (res['message'] as String? ?? '').toLowerCase().contains('created');

  // ── AuthRepository ─────────────────────────────────────────────────────────

  @override
  Future<UserEntity?> checkAuthStatus() async {
    final token = await _storage.getAuthToken();
    final model = await _storage.getUserModel();
    if (token == null || model == null) return null;

    final isValid = await _authService.verifyToken(token);
    if (!isValid) {
      await _storage.clearAuth();
      return null;
    }

    final updated = model.copyWith(lastLogin: DateTime.now());
    await _storage.saveUserModel(updated);
    return updated.toEntity();
  }

  @override
  Future<UserEntity> login({
    required String identifier,
    required String passcode,
  }) async {
    final res = await _authService
        .login(identifier: identifier, passcode: passcode)
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    debugPrint('[AuthRepository] login response: $res');

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'Login failed. Please try again.');
    }

    final token = _extractToken(res);
    if (token == null) throw Exception('Login failed: no token in response.');

    final refreshToken = res['refreshToken'] as String?;
    if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);

    final model = res['user'] != null
        ? UserModel.fromJson(res['user'] as Map<String, dynamic>)
        : await _storage.getUserModel();

    if (model == null) throw Exception('Login failed: no user data.');

    await _storage.saveAuthToken(token);
    await _storage.saveUserModel(model);
    return model.toEntity();
  }

  @override
  Future<String> sendSignupOtp({
    required String email,
    required String phoneNumber,
  }) async {
    final reference = 'reg_${DateTime.now().millisecondsSinceEpoch}';
    final res = await _authService
        .sendOtp(phoneNumber: phoneNumber, email: email, reference: reference)
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    return (res['data']?['otpId'] ?? res['otpId'] ?? reference) as String;
  }

  @override
  Future<String> resendOtp({
    required String email,
    required String phoneNumber,
  }) async {
    final reference = 'resend_${DateTime.now().millisecondsSinceEpoch}';
    final res = await _authService.sendOtp(
        phoneNumber: phoneNumber, email: email, reference: reference);
    return (res['data']?['otpId'] ?? res['otpId'] ?? reference) as String;
  }

  @override
  Future<UserEntity> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
  }) async {
    // Step 1: verify OTP
    final verifyRes = await _authService
        .verifyOtp(otpId: otpId, otp: otp, action: 'registration')
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(verifyRes)) {
      throw Exception(
          verifyRes['message'] ?? 'OTP verification failed. Please try again.');
    }

    // Step 2: register
    final regRes = await _authService
        .signup(email: email, phoneNumber: phoneNumber, passcode: passcode)
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(regRes)) {
      throw Exception(
          regRes['message'] ?? 'Registration failed. Please try again.');
    }

    await _storage.savePin(passcode);

    final token = _extractToken(regRes);
    final refreshToken = regRes['refreshToken'] as String?;

    final model = regRes['user'] != null
        ? UserModel.fromJson(regRes['user'] as Map<String, dynamic>)
        : UserModel(
            userId:
                (regRes['userId'] ?? regRes['data']?['userId'] ?? '') as String,
            email: email,
            phoneNumber: phoneNumber,
            isEmailVerified: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

    await _storage.saveUserModel(model);
    if (token != null) {
      await _storage.saveAuthToken(token);
      if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);
    }

    return model.toEntity();
  }

  @override
  Future<void> completeOnboarding({required int tierNumber}) async {
    await _authService.completeOnboarding(
      bvn: (await _storage.getUserModel())?.bvn ?? '',
      tierNumber: tierNumber,
    );
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    await _storage.saveUserModel(UserModelX.fromEntity(user));
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storage.clearAuth();
  }
}
