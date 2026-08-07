// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implements AuthRepository using AuthService (HTTP) + StorageService (local).
// This is the ONLY file that imports from both the data layer and the service
// layer simultaneously. Everything above this uses only domain types.

import 'package:flutter/foundation.dart';
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

  // Every auth endpoint wraps its payload: { status, message, errorCode, data }.
  // Returns the inner `data` object, falling back to the raw response so a
  // non-enveloped endpoint still works.
  Map<String, dynamic> _payload(Map<String, dynamic> res) {
    final data = res['data'];
    return data is Map<String, dynamic> ? data : res;
  }

  String? _extractToken(Map<String, dynamic> res) {
    final data = _payload(res);
    return (data['accessToken'] ?? data['token'] ?? res['accessToken'])
        as String?;
  }

  String? _extractRefreshToken(Map<String, dynamic> res) =>
      (_payload(res)['refreshToken'] ?? res['refreshToken']) as String?;

  Map<String, dynamic>? _extractUser(Map<String, dynamic> res) {
    final user = _payload(res)['user'] ?? res['user'];
    return user is Map<String, dynamic> ? user : null;
  }

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

    final refreshToken = _extractRefreshToken(res);
    if (refreshToken != null) await _storage.saveRefreshToken(refreshToken);

    final userJson = _extractUser(res);
    final model = userJson != null
        ? UserModel.fromUserResponse(userJson)
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
        .sendOtp(
          phoneNumber: phoneNumber,
          email: email,
          purpose: OtpPurpose.registration,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    return _extractOtpReference(res, reference);
  }

  @override
  Future<String> resendOtp({
    required String email,
    required String phoneNumber,
  }) async {
    final reference = 'resend_${DateTime.now().millisecondsSinceEpoch}';
    final res = await _authService.sendOtp(
      phoneNumber: phoneNumber,
      email: email,
      purpose: OtpPurpose.registration,
    );
    return _extractOtpReference(res, reference);
  }

  // The server returns OtpResponse.otpReference; [fallback] is only a
  // client-side placeholder and will not verify against the server.
  String _extractOtpReference(Map<String, dynamic> res, String fallback) {
    final data = _payload(res);
    return (data['otpReference'] ?? data['otpId'] ?? fallback) as String;
  }

  @override
  Future<UserEntity> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
  }) async {
    // Step 1: verify OTP
    // `otpId` carries the server's otpReference — the domain param keeps its
    // old name to avoid churning the use-case and UI layers.
    final verifyRes = await _authService
        .verifyOtp(
          otpReference: otpId,
          code: otp,
          purpose: OtpPurpose.registration,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(verifyRes)) {
      throw Exception(
          verifyRes['message'] ?? 'OTP verification failed. Please try again.');
    }

    // Step 2: register
    final regRes = await _authService
        .signup(
          otpReference: otpId,
          email: email,
          phoneNumber: phoneNumber,
          passcode: passcode,
          confirmPasscode: confirmPasscode,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(regRes)) {
      throw Exception(
          regRes['message'] ?? 'Registration failed. Please try again.');
    }

    await _storage.savePin(passcode);

    final token = _extractToken(regRes);
    final refreshToken = _extractRefreshToken(regRes);

    final userJson = _extractUser(regRes);
    final model = userJson != null
        ? UserModel.fromUserResponse(userJson)
        : UserModel(
            userId: (_payload(regRes)['customerId'] ?? '') as String,
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

  @override
  Future<void> logoutAll() async {
    try {
      await _authService.logoutAll();
    } catch (_) {}
    await _storage.clearAuth();
  }
}
