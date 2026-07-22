// lib/features/auth/data/auth_service.dart
//
// Moved from: lib/services/auth_services.dart
// Old path kept alive by shim at lib/services/auth_services.dart
//
// Registration flow (3 steps):
//   1. POST /api/v1/auth/send-otp       → { phoneNumber, email, reference, channel }
//   2. POST /api/v1/auth/verify-otp     → { otpId, otp, action: "registration" }
//   3. POST /api/v1/auth/register       → { phoneNumber, email, passcode, deviceFingerprint }
//
// Login flow:
//   POST /api/v1/auth/login             → { identifier, passcode, deviceInfo }
//
// Session:
//   POST /api/v1/auth/refresh-token     → { refreshToken }
//   POST /api/v1/auth/logout/:userId/:sessionId
//
// Profile:
//   GET  /api/v1/profile
//   POST /api/v1/profile/update-profile → { firstName, lastName, email, dateOfBirth }
//
// Onboarding:
//   POST /api/v1/auth/onboarding/complete → { bvn?, tier? }

import 'package:flutter/foundation.dart';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/device_info_services.dart';
import 'package:kudipay/services/storage_services.dart';

class AuthService {
  final DioClient _client;
  final StorageService _storage;

  AuthService(this._storage, this._client);

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
    required String email,
    required String reference,
    String channel = 'EMAIL',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/send-otp',
        data: {
          'phone': phoneNumber,
          'email': email,
          'reference': reference,
          'channel': channel,
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
        '/api/v1/auth/verify-otp',
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
  Future<Map<String, dynamic>> verifyOtp({
    required String otpId,
    required String otp,
    String action = 'registration',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-otp',
        data: {'otpId': otpId, 'otp': otp, 'action': action},
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('OTP verification failed: ${e.toString()}');
    }
  }

  // ── Step 3: Register ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String passcode,
    String? deviceFingerprint,
  }) async {
    final meta = await DeviceInfoService.collect();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'phone': phoneNumber,
          'email': email,
          'passcode': passcode,
          'deviceFingerprint': deviceFingerprint ?? meta.deviceModel,
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
        '/api/v1/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
          'deviceInfo': {
            'deviceModel': meta.deviceModel,
            'ipAddress': meta.ipAddress,
            'location': meta.location,
            'timestamp': meta.timestamp,
          },
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
        '/api/v1/auth/refresh-token',
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
      final response =
          await _client.get<Map<String, dynamic>>('/api/v1/profile');
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
        '/api/v1/profile/update-profile',
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
        '/api/v1/auth/onboarding/complete',
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
  Future<void> logout({String? userId, String? sessionId}) async {
    try {
      final uid = userId ?? (await _storage.getUserModel())?.userId ?? '';
      final sid = sessionId ?? '';
      await _client.post('/api/v1/auth/logout/$uid/$sid', data: {});
    } catch (e) {
      debugPrint(
          '[AuthService] logout server call failed (session still cleared): $e');
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
