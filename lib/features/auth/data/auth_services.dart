// lib/features/auth/data/auth_service.dart
//
// Moved from: lib/services/auth_services.dart
// Old path kept alive by shim at lib/services/auth_services.dart
//
// Request shapes below are verified against the backend's OpenAPI spec
// (GET /v3/api-docs). Every response is enveloped as
// { status, message, errorCode, data } — unwrap via AuthRepositoryImpl.
//
// Registration flow (3 steps):
//   1. POST /api/v1/auth/send-otp   → { identifier?, phoneNumber?, email?, purpose* }
//   2. POST /api/v1/auth/verify-otp → { otpReference*, code*, purpose* }
//   3. POST /api/v1/auth/register   → { otpReference*, phoneNumber*, email*,
//                                       fullName*, passcode*, confirmPasscode*,
//                                       referralCode? }   ← NOT YET MIGRATED
//
// Login flow:
//   POST /api/v1/auth/login         → { identifier*, passcode*,
//                                       deviceFingerprint?, deviceName? }
//
// Session:
//   POST /api/v1/auth/refresh-token → { refreshToken }
//   POST /api/v1/auth/logout        → { refreshToken }
//   POST /api/v1/auth/logout-all    → (no body)
//
// STALE — these paths are absent from the spec and will not resolve:
//   GET  /profile                          (used by verifyToken)
//   POST /profile/update-profile           (used by updateProfile)
//   POST /auth/onboarding/complete         (superseded by /auth/select-tier)

import 'package:flutter/foundation.dart';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/core/utils/device/device_utility.dart';
import 'package:kudipay/services/storage_services.dart';

/// The `purpose` discriminator required by send-otp / verify-otp.
/// Wire values must match the backend's enum exactly.
enum OtpPurpose {
  registration('REGISTRATION'),
  login('LOGIN'),
  forgotPasscode('FORGOT_PASSCODE'),
  deviceLink('DEVICE_LINK'),
  emailChange('EMAIL_CHANGE');

  const OtpPurpose(this.wire);
  final String wire;
}

class AuthService {
  final DioClient _client;
  final StorageService _storage;

  AuthService(this._storage, this._client);

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  // Send at least one of [identifier] / [phoneNumber] / [email] — the server
  // rejects the request otherwise. [phoneNumber] must be E.164 (+234…).
  Future<Map<String, dynamic>> sendOtp({
    String? identifier,
    String? phoneNumber,
    String? email,
    required OtpPurpose purpose,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {
          if (identifier != null) 'identifier': identifier,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
          'purpose': purpose.wire,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to send OTP: ${e.toString()}');
    }
  }

  // ── Verify Email OTP ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
    String otpId = '',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email,
          'otp': code,
          if (otpId.isNotEmpty) 'otpId': otpId,
          'action': 'registration',
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Email verification failed: ${e.toString()}');
    }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────
  // [otpReference] is the value returned by [sendOtp] as data.otpReference.
  Future<Map<String, dynamic>> verifyOtp({
    required String otpReference,
    required String code,
    required OtpPurpose purpose,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'otpReference': otpReference,
          'code': code,
          'purpose': purpose.wire,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('OTP verification failed: ${e.toString()}');
    }
  }

  // ── Step 3: Register ───────────────────────────────────────────────────────
  // [otpReference] must be the value verify-otp was called with.
  // [phoneNumber] must be E.164 (+234…).
  Future<Map<String, dynamic>> signup({
    required String otpReference,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
    String? referralCode,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'otpReference': otpReference,
          'phoneNumber': phoneNumber,
          'email': email,
          'passcode': passcode,
          'confirmPasscode': confirmPasscode,
          if (referralCode != null) 'referralCode': referralCode,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Registration failed: ${e.toString()}');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String passcode,
  }) async {
    final meta = await DeviceInfoService.collect();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
          'deviceName': meta.deviceModel,
          // NOTE: deviceFingerprint is intentionally omitted. It is optional in
          // the API, and DeviceInfoService only yields a coarse OS label
          // ('Android Device') that would be identical across every device —
          // sending that as a fingerprint would corrupt server-side device
          // tracking. Needs device_info_plus or a stored per-install UUID.
        },
      );
      return response.data!;
    } on KudiUnauthorizedException {
      throw KudiApiException('Invalid credentials. Please try again.');
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Login failed: ${e.toString()}');
    }
  }

  // ── Refresh Token ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      return response.data!;
    } catch (e) {
      throw KudiApiException('Token refresh failed: ${e.toString()}');
    }
  }

  // ── Verify Token ───────────────────────────────────────────────────────────
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/profile');
      return response.data != null;
    } on KudiUnauthorizedException {
      return false;
    } catch (e) {
      debugPrint(
          '[AuthService] verifyToken network error — keeping session: $e');
      return true;
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  Future<UserModel> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? bvn,
    String? nin,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
  }) async {
    final existing = await _storage.getUserModel();
    if (existing == null) throw KudiApiException('No user session found.');

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/profile/update-profile',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        },
      );

      final data = response.data!;
      if (data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      return existing.copyWith(
        name: (firstName != null && lastName != null)
            ? '$firstName $lastName'
            : existing.name,
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    } catch (e) {
      debugPrint('[AuthService] updateProfile error: $e');
      return existing.copyWith(
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    }
  }

  // ── Complete Onboarding ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> completeOnboarding({
    required String bvn,
    int? tierNumber,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/onboarding/complete',
        data: {
          if (bvn.isNotEmpty) 'bvn': bvn,
          if (tierNumber != null) 'tier': tierNumber,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Onboarding failed: ${e.toString()}');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      await _client.post('/auth/logout', data: {
        'refreshToken': refreshToken ?? '',
      });
    } catch (e) {
      debugPrint(
          '[AuthService] logout server call failed (session still cleared): $e');
    }
    await _storage.clearAuth();
  }

  // ── Logout All Devices ────────────────────────────────────────────────────
  Future<void> logoutAll() async {
    try {
      await _client.post('/auth/logout-all', data: {});
    } catch (e) {
      debugPrint(
          '[AuthService] logout-all server call failed (session still cleared): $e');
    }
    await _storage.clearAuth();
  }

  // ── Submit User Info (onboarding helper) ───────────────────────────────────
  Future<bool> submitUserInfo(UserInfo userInfo) async {
    try {
      await _storage.saveUserInfo(userInfo);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkAuthStatus() async => _storage.isAuthenticated();
}
