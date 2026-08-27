
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/session_events.dart';
import 'package:kudipay/services/storage_services.dart';

// =============================================================================
// 1. SERVICE PROVIDERS
// =============================================================================

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final authDioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ApiConfig.authBaseUrl,
    storage: StorageService.instance,
    connectivity: ConnectivityService.instance,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(storageServiceProvider),
    ref.read(authDioClientProvider),
  );
});

// =============================================================================
// 2. AUTH NOTIFIER
// =============================================================================
//
// Owns login/logout/session-restore. Registration's multi-step OTP flow
// (send-otp -> verify-otp -> register) is orchestrated by the individual
// signup screens directly against authServiceProvider + registrationFlowProvider
// (see registration_flow_provider.dart) — those screens already own their
// own loading/error UI state, matching the rest of the app's convention.
// Once register() succeeds, the final screen calls [completeSession] below
// so both flows share exactly one place that persists tokens/user and flips
// AuthState — login and registration must not diverge on this.

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;
  StreamSubscription<void>? _sessionExpiredSub;

  AuthNotifier(this._authService, this._storageService) : super(AuthState()) {
    _sessionExpiredSub =
        SessionEvents.instance.onSessionExpired.listen((_) {
      // DioClient's interceptor already cleared storage after a failed
      // refresh; this just makes sure the UI actually reacts to it —
      // without a route table, nothing else will notice the session died.
      if (state.isAuthenticated) {
        state = state.unauthenticated('Your session has expired. Please log in again.');
      }
    });
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  // ── Check auth status on app start ────────────────────────────────────────
  //
  // Cache-first restore against kudikit-auth-service only. The auth-service
  // has no GET /profile and no /auth/me endpoint, so boot MUST NOT try to
  // re-validate the access token against the network (that would 404 into
  // "session lost" for a perfectly good offline session). A cached token +
  // user model are enough to restore the session; the long-lived refresh
  // token stays authoritative and is validated lazily by DioClient's
  // interceptor on the first real 401 — POST /auth/refresh-token either
  // rotates the pair (persisting data.user) or fails with a session-expired
  // event that flips the UI to unauthenticated. No cache => unauthenticated.

  Future<void> _checkAuthStatus() async {
    state = state.loading();
    try {
      final token = await _storageService.getAuthToken();
      final user = await _storageService.getUserModel();

      if (token != null && user != null) {
        final updatedUser = user.copyWith(lastLogin: DateTime.now());
        await _storageService.saveUserModel(updatedUser);
        state = state.authenticated(updatedUser, token);

        // SLICE 6 (MO-4): authenticated boot reconciles KYC from the server.
        // The auth-service can change state asynchronously (address poller
        // PENDING_AGENT_VISIT -> VERIFIED, MANUAL_REVIEW -> VERIFIED/REJECTED),
        // so a cached-but-stale restore must not require a logout/login to
        // discover it. Fire-and-forget + best-effort: refreshKycStatus swallows
        // every error and never destroys a session (cache-first restore intact).
        unawaited(refreshKycStatus());
        unawaited(refreshTierUpgradeStatus());
      } else {
        state = state.unauthenticated();
      }
    } catch (e) {
      state = state.error('Failed to restore session. Please log in again.');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();
    try {
      final response = await _authService
          .login(identifier: email, passcode: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception(response['message'] ?? 'Login failed. Please try again.');
      }

      // 202 DEVICE_LINK challenge: this device's fingerprint isn't trusted for
      // the account yet, and the auth-service has ALREADY dispatched the OTP.
      // Do NOT call completeSession here (there is no session to complete) —
      // store the challenge so the login page can route into the existing
      // device-verification flow (SignInVerifyEmailScreen), which finishes via
      // verifyOtp(DEVICE_LINK) + verifyDeviceLogin() + completeSession().
      if (data['deviceVerificationRequired'] == true) {
        final otpReference = data['otpReference'] as String?;
        final maskedIdentifier = data['maskedIdentifier'] as String?;
        final expiresInSeconds = data['expiresInSeconds'] as int?;
        if (otpReference == null || otpReference.isEmpty) {
          throw Exception(
              'Device verification required but no OTP reference was returned.');
        }
        state = state.deviceVerificationRequired(DeviceVerificationChallenge(
          otpReference: otpReference,
          maskedIdentifier: maskedIdentifier ?? '',
          expiresInSeconds: expiresInSeconds ?? 300,
        ));
        return;
      }

      await completeSession(data);

      // Refresh the locally-stored passcode hash so biometric/local unlock
      // stays in sync with whatever the server just accepted. Best-effort —
      // a failure here shouldn't block a successful login.
      try {
        await _storageService.savePasscode(password, phoneNumber: email);
      } catch (_) {}
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Complete session (shared by login() and registration's final step) ────
  //
  // [data] is the `data` object of an AuthTokenResponse envelope:
  // { accessToken, refreshToken, tokenType, expiresIn, user: {...} }.

  Future<void> completeSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (accessToken == null || accessToken.isEmpty || userJson == null) {
      throw Exception('Malformed session response from server.');
    }

    final user = UserModel.fromAuthResponse(userJson);

    await _storageService.saveAuthToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storageService.saveRefreshToken(refreshToken);
    }
    await _storageService.saveUserModel(user);
    state = state.authenticated(user, accessToken);
  }

  // ── Update User ────────────────────────────────────────────────────────────

  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user == null) return;
    try {
      await _storageService.saveUserModel(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (e) {}
  }

  // ── Update KYC status ─────────────────────────────────────────────────────
  //
  // TRANSITIONAL local-optimistic mutation (Slice 4B): mutates the cached
  // UserModel's convenience booleans only. It does NOT submit anything to the
  // server (the real KYC submission APIs are a Slice 5 deliverable), so it
  // never drives the authoritative typed state (kycStatus/idDocumentStatus/
  // addressStatus) — those remain server-owned and are overwritten wholesale
  // by the next server sync (fromAuthResponse / refreshKycStatus). The five
  // existing callers (confirm_info, verify_address, selfie_capture,
  // liveness_capture, upload_ID) keep working unchanged.

  Future<void> updateKycStatus({
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
    String? bvn,
    String? nin,
  }) async {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWith(
      isBvnVerified: isBvnVerified ?? state.user!.isBvnVerified,
      isAddressVerified: isAddressVerified ?? state.user!.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? state.user!.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? state.user!.isDocumentVerified,
      bvn: bvn ?? state.user!.bvn,
      nin: nin ?? state.user!.nin,
    );
    await updateUser(updatedUser);
  }

  // ── Refresh KYC status ────────────────────────────────────────────────────
  //
  // ON-DEMAND server reconciliation (Slice 4B): GET /auth/kyc/status, merge
  // the authoritative summary into the cached UserModel (server wins via
  // copyWithKyc — stale local booleans are never preserved over server KYC
  // data), then persist and publish. NON-BLOCKING and best-effort: a network
  // failure must never destroy a session, so every error is swallowed and the
  // cached state is left untouched. This is NOT called from _checkAuthStatus()
  // (that would regress Slice 4A's cache-first restore) and is NOT a
  // session/token validator — its only job is keeping the cached KYC state
  // aligned with the auth-service.
  Future<void> refreshKycStatus() async {
    if (state.user == null) return;
    try {
      final kyc = await _authService.getKycStatus();
      final updatedUser = state.user!.copyWithKyc(kyc);
      await _storageService.saveUserModel(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (_) {
      // Optional refresh — a transient failure must not destroy the session.
    }
  }

  // ── Apply an authoritative KYC summary (Slice 5) ───────────────────────────
  // Same server-wins merge as refreshKycStatus, but from an in-memory
  // KycStatusSummary (the response of a verify-* submission) instead of a
  // GET /auth/kyc/status — avoids a redundant round-trip. The typed enums and
  // convenience booleans are both re-derived via copyWithKyc; stale cached
  // local flags are never preserved over server KYC data.
  Future<void> applyKyc(KycStatusSummary kyc) async {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWithKyc(kyc);
    await _storageService.saveUserModel(updatedUser);
    state = state.copyWith(user: updatedUser);
  }

  // ── Tier upgrade status (backend MEGA review lifecycle) ───────────────────
  // Best-effort fresh read of the latest TierUpgradeRequest so the cached
  // UserModel carries the internal SUBMITTED/REVIEWING/APPROVED/REJECTED state
  // + admin notes. The UI keeps the PRD "Pending" display — the staged labels
  // are never surfaced. NON-BLOCKING: every error is swallowed (cache-first
  // restore intact); a null status/notes means "no request" and is a no-op.
  Future<void> refreshTierUpgradeStatus() async {
    if (state.user == null) return;
    try {
      final info = await _authService.getTierUpgradeStatus();
      if (info.status == null && info.reviewNotes == null) return;
      final updatedUser = state.user!.copyWith(
        tierUpgradeStatus: info.status,
        tierUpgradeReviewNotes: info.reviewNotes,
      );
      await _storageService.saveUserModel(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (_) {
      // Optional refresh — a transient failure must not destroy the session.
    }
  }

  // ── KYC submissions (Slice 5) ─────────────────────────────────────────────
  // Submit to the auth-service and persist the authoritative summary via
  // applyKyc. A 400 rejection (KudiApiException) means the REJECTED state was
  // already saved server-side while the error body carries only a message —
  // so before rethrowing (letting the UI surface the server message) we
  // reconcile the cached UserModel with a GET /auth/kyc/status. Best-effort:
  // a reconcile failure must not hide the original rejection.
  Future<KycStatusSummary> verifyBvn({
    required String bvn,
    required String selfieImageBase64,
  }) async {
    if (state.user == null) {
      throw const KudiApiException('No user session found.');
    }
    try {
      final summary = await _authService.verifyBvn(
          bvn: bvn, selfieImageBase64: selfieImageBase64);
      await applyKyc(summary);
      return summary;
    } on KudiApiException {
      await refreshKycStatus();
      rethrow;
    }
  }

  Future<KycStatusSummary> verifyNin({
    required String nin,
    required String selfieImageBase64,
  }) async {
    if (state.user == null) {
      throw const KudiApiException('No user session found.');
    }
    try {
      final summary = await _authService.verifyNin(
          nin: nin, selfieImageBase64: selfieImageBase64);
      await applyKyc(summary);
      return summary;
    } on KudiApiException {
      await refreshKycStatus();
      rethrow;
    }
  }

  Future<KycStatusSummary> verifyIdDocument({
    required String documentType,
    required String frontImageBase64,
    String? backImageBase64,
  }) async {
    if (state.user == null) {
      throw const KudiApiException('No user session found.');
    }
    try {
      final summary = await _authService.verifyIdDocument(
        documentType: documentType,
        frontImageBase64: frontImageBase64,
        backImageBase64: backImageBase64,
      );
      await applyKyc(summary);
      return summary;
    } on KudiApiException {
      await refreshKycStatus();
      rethrow;
    }
  }

  Future<KycStatusSummary> verifyAddress({
    required String houseNumber,
    required String street,
    String? landmark,
    String? area,
    required String lga,
    required String city,
    required String addressState,
    required String utilityBillImageBase64,
    double? latitude,
    double? longitude,
  }) async {
    if (state.user == null) {
      throw const KudiApiException('No user session found.');
    }
    try {
      final summary = await _authService.verifyAddress(
        houseNumber: houseNumber,
        street: street,
        landmark: landmark,
        area: area,
        lga: lga,
        city: city,
        state: addressState,
        utilityBillImageBase64: utilityBillImageBase64,
        latitude: latitude,
        longitude: longitude,
      );
      await applyKyc(summary);
      return summary;
    } on KudiApiException {
      await refreshKycStatus();
      rethrow;
    }
  }

  // ── Select tier (Slice 6 — server-authoritative) ──────────────────────────
  // POST /auth/select-tier, then merge the returned server state (tier,
  // pendingTier, registrationComplete) into the cached UserModel and publish.
  // Local tier state remains a display/cache fallback only — the server's
  // pendingTier/tier is the routing authority (see KycFlowManager).
  Future<UserModel> selectTier(int tierNumber) async {
    if (state.user == null) {
      throw const KudiApiException('No user session found.');
    }
    final updatedUser = await _authService.selectTier(tierNumber: tierNumber);
    await _storageService.saveUserModel(updatedUser);
    state = state.copyWith(user: updatedUser);
    return updatedUser;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storageService.clearAll();
    state = state.unauthenticated();
  }
}

// =============================================================================
// 3. MAIN AUTH PROVIDER
// =============================================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// =============================================================================
// 4. COMPUTED PROVIDERS
// =============================================================================

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

final kycProgressProvider = Provider<double>((ref) {
  return ref.watch(currentUserProvider)?.kycProgress ?? 0.0;
});

final isKycCompleteProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isKycComplete ?? false;
});

// ── Simple UI state providers ─────────────────────────────────────────────────

final pinVisibilityProvider = StateProvider<bool>((ref) => false);
final confirmPinVisibilityProvider = StateProvider<bool>((ref) => false);
final userIdProvider = StateProvider<String?>((ref) => null);
final userProvider = StateProvider<String>((ref) => '');
final userEmailProvider = StateProvider<String>((ref) => '');

final userProfileProvider = Provider<UserProfile>((ref) {
  return UserProfile(
    userId: ref.watch(userIdProvider),
    name: ref.watch(userProvider),
    email: ref.watch(userEmailProvider),
  );
});
