
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/auth/auth_state.dart';
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
  // verifyToken() hits GET /profile; if the stored access token is expired,
  // DioClient's interceptor transparently attempts a refresh + retry before
  // this ever sees a failure — so a true/false here already reflects the
  // outcome *after* that silent refresh attempt, not just the raw token's
  // literal validity.

  Future<void> _checkAuthStatus() async {
    state = state.loading();
    try {
      final token = await _storageService.getAuthToken();
      final user = await _storageService.getUserModel();

      if (token != null && user != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          final updatedUser = user.copyWith(lastLogin: DateTime.now());
          await _storageService.saveUserModel(updatedUser);
          state = state.authenticated(updatedUser, token);
        } else {
          await logout();
        }
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
