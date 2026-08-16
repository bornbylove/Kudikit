// lib/features/auth/data/auth_services.dart
//
// Request shapes below are verified against the backend's OpenAPI spec
// (GET /v3/api-docs). Every response is enveloped as
// { status, message, errorCode, data } — unwrap via AuthRepositoryImpl.
//
// Registration flow (3 steps):
//   1. POST /api/v1/auth/send-otp   → { identifier?, phoneNumber?, email?, purpose* }
//   2. POST /api/v1/auth/verify-otp → { otpReference*, code*, purpose* }
//   3. POST /api/v1/auth/register   → { otpReference*, phoneNumber*, email*,
//                                       passcode*, confirmPasscode*,
//                                       referralCode? }
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
// Session restore exchanges the refresh token via /auth/refresh-token — see
// AuthRepositoryImpl.checkAuthStatus. There is no token-introspection endpoint.
//
// STALE — this path is absent from the spec and will not resolve:
//   POST /profile/update-profile           (used by updateProfile)

import 'package:flutter/foundation.dart';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/core/utils/device/device_utility.dart';
import 'package:kudipay/core/services/storage_services.dart';

/// Maps the app's 1-based tier number onto the backend's tier enum.
///
/// Throws rather than defaulting: an unrecognised value silently becoming
/// 'BASIC' would quietly downgrade a user who picked Pro or Mega, whereas the
/// throw is caught by the tier screen and surfaces as a retryable error.
String tierWireValue(int tierNumber) {
  switch (tierNumber) {
    case 1:
      return 'BASIC';
    case 2:
      return 'PRO';
    case 3:
      return 'MEGA';
    default:
      throw ArgumentError.value(
        tierNumber,
        'tierNumber',
        'Expected 1 (Basic), 2 (Pro) or 3 (Mega)',
      );
  }
}

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
    String? deviceFingerprint,
  }) async {
    final meta = await DeviceInfoService.collect();
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
          // Optional here, but binding the device at signup should spare the
          // user a verification challenge on their first login.
          if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
          'deviceName': meta.deviceModel,
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
    required String deviceFingerprint,
  }) async {
    final meta = await DeviceInfoService.collect();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
          // Required since the device-verification release. This is a stable
          // per-install UUID from StorageService, not a hardware id.
          'deviceFingerprint': deviceFingerprint,
          'deviceName': meta.deviceModel,
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
  // Exception types are preserved rather than flattened into KudiApiException:
  // session restore has to tell "the server rejected this token" apart from
  // "the device is offline", and only the former should end the session.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      return response.data!;
    } on KudiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Token refresh failed: ${e.toString()}');
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

  // ── Forgot Passcode ────────────────────────────────────────────────────────
  // Three steps, mirroring registration:
  //   1. POST /auth/forgot-passcode/send-otp  { identifier?/phoneNumber?/email?,
  //                                             purpose: FORGOT_PASSCODE }
  //   2. POST /auth/verify-otp                { otpReference, code,
  //                                             purpose: FORGOT_PASSCODE }
  //   3. POST /auth/forgot-passcode/reset     { otpReference, newPasscode,
  //                                             confirmPasscode }
  //
  // Step 2 is the shared verify-otp endpoint — ResetPasscodeRequest carries no
  // `code` field, so the reference must already have been verified.
  Future<Map<String, dynamic>> sendForgotPasscodeOtp({
    String? identifier,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/forgot-passcode/send-otp',
        data: {
          if (identifier != null) 'identifier': identifier,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
          'purpose': OtpPurpose.forgotPasscode.wire,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to send reset code: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> resetPasscode({
    required String otpReference,
    required String newPasscode,
    required String confirmPasscode,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/forgot-passcode/reset',
        data: {
          'otpReference': otpReference,
          'newPasscode': newPasscode,
          'confirmPasscode': confirmPasscode,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Passcode reset failed: ${e.toString()}');
    }
  }

  // ── Select Tier ────────────────────────────────────────────────────────────
  // Replaces the old /auth/onboarding/complete call, which is not an endpoint
  // this API has. Returns ApiResponseUserResponse.
  Future<Map<String, dynamic>> selectTier({required int tierNumber}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/select-tier',
        data: {'tier': tierWireValue(tierNumber)},
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Tier selection failed: ${e.toString()}');
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
