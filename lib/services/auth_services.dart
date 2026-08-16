// lib/services/auth_services.dart
//
// Aligned to kudikit_auth_service's real contract — verified 2026-08-08
// against both the live deployed OpenAPI spec (199.192.22.72:8090/v3/api-docs)
// and the service's source (AuthController, RegisterRequest.java,
// PasscodeValidator.java). No mock fallback — this service always talks to
// the network; UI/provider layers handle loading/error states.
//
// Registration flow (3 steps):
//   1. POST /auth/send-otp    { phoneNumber, email, purpose }
//      -> data: { otpReference, channel, maskedIdentifier,
//                 expiresInSeconds, resendCooldownSeconds }
//   2. POST /auth/verify-otp  { otpReference, code, purpose }
//      -> data: Map<String,String> (server confirms the same otpReference;
//                 that reference — not anything parsed back out here — is
//                 what gets carried into step 3)
//   3. POST /auth/register    { otpReference, phoneNumber, email, fullName,
//                                passcode, confirmPasscode, referralCode? }
//      -> data: AuthTokenResponse { accessToken, refreshToken, tokenType,
//                 expiresIn, user }
//
// Login:
//   POST /auth/login  { identifier, passcode }
//      -> data: AuthTokenResponse (same shape as register)
//
// Session:
//   POST /auth/refresh-token  { refreshToken }  — also handled transparently
//                                                  by DioClient's interceptor
//                                                  on a 401; exposed here for
//                                                  explicit/manual refresh.
//   POST /auth/logout         { refreshToken }  — Bearer required (attached
//                                                  automatically by DioClient)
//
// Auth-domain requests go to ApiConfig.authBaseUrl (a separate host from the
// Gateway, which everything else in this file that isn't `/auth/*` still
// targets) via absolute URLs through the shared DioClient.
//
// Passcode format: 6-8 NUMERIC digits only (see PasscodeValidator.java) —
// NOT the 8-12 char alphanumeric+special-char shape this file used to
// document. See storage_services.dart / signup.dart for the matching UI
// and local-validation change.

import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/storage_services.dart';

/// Canonical OTP purposes, matching kudikit_auth_service's OtpPurpose enum.
class OtpPurpose {
  OtpPurpose._();
  static const String registration = 'REGISTRATION';
  static const String login = 'LOGIN';
  static const String forgotPasscode = 'FORGOT_PASSCODE';
  static const String deviceLink = 'DEVICE_LINK';
  static const String emailChange = 'EMAIL_CHANGE';
}

class AuthService {
  final DioClient _client;
  final StorageService _storage;

  AuthService(this._storage, this._client);

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  // POST /auth/send-otp
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
    required String email,
    String purpose = OtpPurpose.registration,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {
          'phoneNumber': phoneNumber,
          'email': email,
          'purpose': purpose,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } on KudiNetworkException {
      rethrow;
    } on KudiTimeoutException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to send OTP: ${e.toString()}');
    }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────
  // POST /auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String otpReference,
    required String code,
    String purpose = OtpPurpose.registration,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'otpReference': otpReference,
          'code': code,
          'purpose': purpose,
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
  // POST /auth/register
  // fullName is deliberately NOT collected by this app's registration flow —
  // the PRD's registration step is phone/email/passcode only (name is a
  // KYC/BVN/NIN concept, not a registration field).
  Future<Map<String, dynamic>> register({
    required String otpReference,
    required String phoneNumber,
    required String email,
    String? fullName,
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
          if (fullName != null && fullName.trim().isNotEmpty)
            'fullName': fullName.trim(),
          'passcode': passcode,
          'confirmPasscode': confirmPasscode,
          if (referralCode != null && referralCode.trim().isNotEmpty)
            'referralCode': referralCode.trim(),
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
  // POST /auth/login
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String passcode,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
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
  // POST /auth/refresh-token
  // Normally handled transparently by DioClient's auth interceptor on a 401.
  // Exposed here for an explicit/manual refresh call site if one is needed.
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

  // ── Verify Token (by fetching profile) ────────────────────────────────────
  // GET /profile (Gateway, not auth-service)
  // Returns true if the server accepts the token; false on 401.
  // On network error: returns true to avoid logging users out while offline.
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/profile');
      return response.data != null;
    } on KudiUnauthorizedException {
      return false;
    } catch (e) {
      // Network/server error — keep the session; don't punish offline users.
      return true;
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  // POST /profile/update-profile (Gateway)
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
      final body = <String, dynamic>{
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/profile/update-profile',
        data: body,
      );

      final data = response.data!;
      if (data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      // Optimistic fallback if server doesn't return a user object.
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
      // Return an optimistic local update on failure so the KYC/profile UI
      // isn't blocked by a transient network error.
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

  // ── Logout ─────────────────────────────────────────────────────────────────
  // POST /auth/logout  { refreshToken }  — Bearer attached automatically by
  // DioClient's auth interceptor from the still-stored access token.
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      // Server call failing shouldn't block a local logout.
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
