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
//                                passcode, confirmPasscode, referralCode?,
//                                deviceFingerprint, deviceName }
//      -> data: AuthTokenResponse { accessToken, refreshToken, tokenType,
//                 expiresIn, user }
//
// Login:
//   POST /auth/login  { identifier, passcode, deviceFingerprint, deviceName }
//      -> data: AuthTokenResponse (same shape as register)
//
// Device identity: every register/login carries the stable per-install
// `deviceFingerprint` (StorageService.getOrCreateDeviceFingerprint) plus an
// optional `deviceName`. LoginRequest.deviceFingerprint is @NotBlank, and
// RegisterRequest.deviceFingerprint — when present — trusts the registering
// device immediately, so the very next login on that device skips the
// DEVICE_LINK challenge.
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
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/device_info_services.dart';
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
  // For REGISTRATION the body is { phoneNumber, email, purpose }. For every
  // other purpose (LOGIN, FORGOT_PASSCODE, DEVICE_LINK, EMAIL_CHANGE) the
  // contract requires { identifier, purpose } instead — pass [identifier].
  Future<Map<String, dynamic>> sendOtp({
    String? identifier,
    String? phoneNumber,
    String? email,
    String purpose = OtpPurpose.registration,
  }) async {
    try {
      final isRegistration = purpose == OtpPurpose.registration;
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/send-otp',
        data: isRegistration
            ? {
                'phoneNumber': phoneNumber,
                'email': email,
                'purpose': purpose,
              }
            : {
                'identifier': identifier,
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
      final deviceFingerprint =
          await _storage.getOrCreateDeviceFingerprint();
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
          'deviceFingerprint': deviceFingerprint,
          'deviceName': DeviceInfoService.getDeviceName(),
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
  // `deviceFingerprint` is @NotBlank server-side (LoginRequest.java) — a login
  // from a fingerprint not already trusted for the account returns a 202
  // DEVICE_LINK challenge envelope instead of a session; that branch is
  // handled at the provider/flow layer, not here.
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String passcode,
  }) async {
    try {
      final deviceFingerprint =
          await _storage.getOrCreateDeviceFingerprint();
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
          'deviceFingerprint': deviceFingerprint,
          'deviceName': DeviceInfoService.getDeviceName(),
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

  // ── Complete Device Verification Login ─────────────────────────────────────
  // POST /auth/login/verify-device
  // Consumes the DEVICE_LINK OTP reference produced by the login 202 challenge
  // (which the auth-service had already dispatched). Called ONLY after the
  // code has been confirmed via verifyOtp(... purpose: DEVICE_LINK). Reuses the
  // SAME persistent deviceFingerprint that triggered the challenge — no new
  // fingerprint is created here. Returns the full AuthTokenResponse envelope.
  Future<Map<String, dynamic>> verifyDeviceLogin({
    required String otpReference,
  }) async {
    try {
      final deviceFingerprint =
          await _storage.getOrCreateDeviceFingerprint();
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login/verify-device',
        data: {
          'otpReference': otpReference,
          'deviceFingerprint': deviceFingerprint,
          'deviceName': DeviceInfoService.getDeviceName(),
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException(
          'Device verification failed: ${e.toString()}');
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

  // ── Get KYC Status ──────────────────────────────────────────────────────────
  // GET /auth/kyc/status (auth-domain, Bearer attached automatically by
  // DioClient's interceptor).
  //
  // ON-DEMAND ONLY (Slice 4B): this is an explicit, caller-triggered read for
  // reconciling server-authoritative KYC state — entering the KYC flow or after
  // a KYC operation. It is NOT a boot-time call, NOT a session validator, and
  // NOT a token validator. Calling it in authProvider._checkAuthStatus() would
  // regress Slice 4A's cache-first restore.
  Future<KycStatusSummary> getKycStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/auth/kyc/status',
      );
      final body = response.data ?? <String, dynamic>{};
      final data =
          (body['data'] as Map<String, dynamic>?) ?? body;
      return KycStatusSummary.fromJson(data);
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to load KYC status: ${e.toString()}');
    }
  }

  // ── Tier Upgrade Status (backend MEGA review lifecycle) ───────────────────
  // GET /auth/kyc/tier-upgrade/status (auth-domain). Returns the latest
  // TierUpgradeRequest (targetTier/status/reviewNotes/submittedAt/decidedAt) —
  // the SUBMITTED -> REVIEWING -> APPROVED/REJECTED lifecycle the auth-service
  // added for the human-gated MEGA (tier 3) upgrade. The mobile carries it
  // internally (PRD "Pending" display); the staged labels are never surfaced.
  Future<TierUpgradeStatusInfo> getTierUpgradeStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/auth/kyc/tier-upgrade/status',
      );
      final body = response.data ?? <String, dynamic>{};
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return TierUpgradeStatusInfo.fromJson(data);
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException(
          'Failed to load tier upgrade status: ${e.toString()}');
    }
  }

  // ── KYC submissions (Slice 5) ──────────────────────────────────────────────
  // POST /auth/kyc/verify-bvn | verify-nin | verify-id-document | verify-address
  // (auth-domain, Bearer attached automatically by DioClient's interceptor).
  // Each returns an ApiResponse whose `data` is the FULL KycVerification
  // entity; the mobile maps the seven authoritative summary fields into
  // KycStatusSummary (the same parser used by getKycStatus) plus the registry
  // identity details (fullName/dateOfBirth) the BVN/NIN confirm screen needs.
  //
  // REJECTIONS ARE 400s: the REJECTED state is persisted server-side but the
  // error body carries only a message (no entity), so callers must follow a
  // 400 with refreshKycStatus() to reconcile the authoritative state.
  Future<KycStatusSummary> verifyBvn({
    required String bvn,
    required String selfieImageBase64,
  }) {
    return _submitKyc('/auth/kyc/verify-bvn', {
      'bvn': bvn,
      'selfieImageBase64': selfieImageBase64,
    });
  }

  Future<KycStatusSummary> verifyNin({
    required String nin,
    required String selfieImageBase64,
  }) {
    return _submitKyc('/auth/kyc/verify-nin', {
      'nin': nin,
      'selfieImageBase64': selfieImageBase64,
    });
  }

  Future<KycStatusSummary> verifyIdDocument({
    required String documentType,
    required String frontImageBase64,
    String? backImageBase64,
  }) {
    return _submitKyc('/auth/kyc/verify-id-document', {
      'documentType': documentType,
      'frontImageBase64': frontImageBase64,
      if (backImageBase64 != null && backImageBase64.isNotEmpty)
        'backImageBase64': backImageBase64,
    });
  }

  Future<KycStatusSummary> verifyAddress({
    required String houseNumber,
    required String street,
    String? landmark,
    String? area,
    required String lga,
    required String city,
    required String state,
    required String utilityBillImageBase64,
    double? latitude,
    double? longitude,
  }) {
    return _submitKyc('/auth/kyc/verify-address', {
      'houseNumber': houseNumber,
      'street': street,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      if (area != null && area.isNotEmpty) 'area': area,
      'lga': lga,
      'city': city,
      'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'utilityBillImageBase64': utilityBillImageBase64,
    });
  }

  Future<KycStatusSummary> _submitKyc(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(path,
          data: body);
      final envelope = response.data ?? <String, dynamic>{};
      final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
      return KycStatusSummary.fromJson(data);
    } on KudiApiException {
      rethrow;
    } on KudiServerException {
      rethrow;
    } on KudiUnauthorizedException {
      rethrow;
    } on KudiNetworkException {
      rethrow;
    } on KudiTimeoutException {
      rethrow;
    } catch (e) {
      throw KudiApiException('KYC submission failed: ${e.toString()}');
    }
  }

  // ── Select Tier (Slice 6 — server-authoritative) ─────────────────────────
  // POST /auth/select-tier  { tier: "BASIC" | "PRO" | "MEGA" }  (auth-domain,
  // Bearer attached automatically by DioClient's interceptor). The auth-service
  // records pendingTier immediately and grants tier once its KYC requirements
  // are met. Returns the full UserResponse envelope; the mobile maps it onto the
  // cached UserModel (server tier/pendingTier wins) rather than trusting local
  // selection state.
  Future<UserModel> selectTier({
    required int tierNumber,
  }) async {
    final tierName = switch (tierNumber) {
      2 => 'PRO',
      3 => 'MEGA',
      _ => 'BASIC',
    };
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/select-tier',
        data: {'tier': tierName},
      );
      final envelope = response.data ?? <String, dynamic>{};
      final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
      final existing = await _storage.getUserModel();
      return UserModel.fromAuthResponse(data, existing: existing);
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to select tier: ${e.toString()}');
    }
  }

  // ── Gateway Profile (Slice 6 — MO-6) ──────────────────────────────────────
  // GET /profile (Gateway). The ProfileResponseDTO exposes account.tier /
  // account.kycStatus, verification.{bvn,nin}.{verified,masked} and
  // verification.address.status — the server-authoritative profile surface the
  // Profile screen should consume. Returns the raw `data` map so the screen can
  // map exactly the fields it renders (no premature model coupling).
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/profile');
      final envelope = response.data ?? <String, dynamic>{};
      final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
      return data;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to load profile: ${e.toString()}');
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
