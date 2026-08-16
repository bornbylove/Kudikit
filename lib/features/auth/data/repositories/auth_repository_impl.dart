// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implements AuthRepository using AuthService (HTTP) + StorageService (local).
// This is the ONLY file that imports from both the data layer and the service
// layer simultaneously. Everything above this uses only domain types.

import 'package:flutter/foundation.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/core/utils/phone_number.dart';
import 'package:kudipay/features/auth/data/auth_services.dart';

import 'package:kudipay/features/auth/domain/entities/login_result.dart';
import 'package:kudipay/features/auth/domain/entities/user_entities.dart';
import 'package:kudipay/features/auth/domain/repositories/auth_repositories.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/model/user/user_model_extension.dart';
// ADD

import 'package:kudipay/core/services/storage_services.dart';

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

    // Validate by exchanging the refresh token for a fresh access token.
    // This previously called GET /profile, which this API does not have — the
    // 404 fell through to the catch-all and every session was reported valid,
    // so a revoked or expired token still restored a "logged in" app.
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // Nothing to validate against. Keep the session: the access token will
      // be rejected on first use, and AuthInterceptor clears storage on 401.
      return model.toEntity();
    }

    try {
      final res = await _authService.refreshToken(refreshToken);

      if (!_isSuccess(res)) {
        await _storage.clearAuth();
        return null;
      }

      final access = _extractToken(res);
      if (access == null) {
        await _storage.clearAuth();
        return null;
      }
      await _storage.saveAuthToken(access);

      // The backend returns a refreshToken alongside the access token, so
      // persist it in case refresh tokens are rotated on use.
      final rotated = _extractRefreshToken(res);
      if (rotated != null && rotated.isNotEmpty) {
        await _storage.saveRefreshToken(rotated);
      }

      final updated = model.copyWith(lastLogin: DateTime.now());
      await _storage.saveUserModel(updated);
      return updated.toEntity();
    } on KudiUnauthorizedException {
      // The only case where the server actively rejected the session.
      await _storage.clearAuth();
      return null;
    } catch (e) {
      // Offline, timeout or a server-side fault — keep the session rather than
      // signing the user out because their connection dropped on launch.
      debugPrint(
          '[AuthRepository] session refresh failed, keeping session: $e');
      return model.toEntity();
    }
  }

  @override
  Future<LoginResult> login({
    required String identifier,
    required String passcode,
  }) async {
    final fingerprint = await _storage.getOrCreateDeviceFingerprint();

    final res = await _authService
        .login(
          identifier: identifier,
          passcode: passcode,
          deviceFingerprint: fingerprint,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'Login failed. Please try again.');
    }

    // The credentials were accepted but this install is not a known device.
    // No tokens are issued; the caller continues through device verification.
    final payload = _payload(res);
    if (payload['deviceVerificationRequired'] == true) {
      final reference = payload['otpReference'] as String?;
      if (reference == null) {
        throw Exception('Device verification required but no reference given.');
      }
      return LoginNeedsDeviceVerification(
        otpReference: reference,
        maskedIdentifier: payload['maskedIdentifier'] as String?,
        expiresInSeconds: payload['expiresInSeconds'] as int?,
      );
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
    return LoginSuccess(model.toEntity());
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
    String? referralCode,
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
          deviceFingerprint: await _storage.getOrCreateDeviceFingerprint(),
          referralCode: (referralCode != null && referralCode.isNotEmpty)
              ? referralCode
              : null,
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
  Future<UserEntity> selectTier({required int tierNumber}) async {
    final res = await _authService.selectTier(tierNumber: tierNumber);

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'Could not save your tier.');
    }

    final userJson = _extractUser(res) ?? _payload(res);
    final existing = await _storage.getUserModel();

    // The response is a UserResponse, which carries no KYC flags — merge onto
    // the stored model so selecting a tier does not wipe verification state.
    final updated = UserModel.fromUserResponse(userJson);
    final merged = existing == null
        ? updated
        : existing.copyWith(
            name: updated.name ?? existing.name,
            selectedTier: updated.selectedTier,
          );

    await _storage.saveUserModel(merged);
    return merged.toEntity();
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    await _storage.saveUserModel(UserModelX.fromEntity(user));
  }

  @override
  Future<String> sendForgotPasscodeOtp({required String identifier}) async {
    final trimmed = identifier.trim();
    final phone = normalizeNigerianPhone(trimmed);

    // send-otp takes email and phoneNumber as distinct fields, so route the
    // single input to whichever it actually is.
    final res = await _authService
        .sendForgotPasscodeOtp(
          phoneNumber: looksLikeNigerianPhone(trimmed) ? phone : null,
          email: looksLikeNigerianPhone(trimmed) ? null : trimmed,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'Could not send the reset code.');
    }

    final reference = _extractOtpReference(res, '');
    if (reference.isEmpty) {
      throw Exception('Could not start the reset — no reference returned.');
    }
    return reference;
  }

  @override
  Future<void> verifyForgotPasscodeOtp({
    required String otpReference,
    required String code,
  }) async {
    final res = await _authService
        .verifyOtp(
          otpReference: otpReference,
          code: code,
          purpose: OtpPurpose.forgotPasscode,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'That code is not valid.');
    }
  }

  @override
  Future<void> resetPasscode({
    required String otpReference,
    required String newPasscode,
    required String confirmPasscode,
  }) async {
    final res = await _authService
        .resetPasscode(
          otpReference: otpReference,
          newPasscode: newPasscode,
          confirmPasscode: confirmPasscode,
        )
        .timeout(const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out.'));

    if (!_isSuccess(res)) {
      throw Exception(res['message'] ?? 'Could not reset your passcode.');
    }

    // The old passcode is no longer valid anywhere — drop any local session so
    // the user signs in fresh with the new one.
    await _storage.clearAuth();
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
