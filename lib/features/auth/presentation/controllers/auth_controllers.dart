// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/network/dio_provider.dart';
import 'package:kudipay/core/singleton/service_providers.dart';
import 'package:kudipay/features/auth/data/auth_services.dart';
import 'package:kudipay/features/auth/domain/repositories/auth_repositories.dart';

import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kudipay/features/auth/domain/usecases/auth_usecases.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/model/user/user_model_extension.dart';
import '../../domain/auth_state.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/user_entities.dart';

export 'package:kudipay/features/auth/domain/auth_state.dart';

// =============================================================================
// Dependency providers
// =============================================================================

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(storageServiceProvider),
    ref.read(dioClientProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authService: ref.read(authServiceProvider),
    storage: ref.read(storageServiceProvider),
  );
});

final checkAuthUseCaseProvider =
    Provider((ref) => CheckAuthUseCase(ref.read(authRepositoryProvider)));
final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
final sendSignupOtpUseCaseProvider =
    Provider((ref) => SendSignupOtpUseCase(ref.read(authRepositoryProvider)));
final resendOtpUseCaseProvider =
    Provider((ref) => ResendOtpUseCase(ref.read(authRepositoryProvider)));
final verifyOtpAndRegisterUseCaseProvider = Provider(
    (ref) => VerifyOtpAndRegisterUseCase(ref.read(authRepositoryProvider)));
final selectTierUseCaseProvider =
    Provider((ref) => SelectTierUseCase(ref.read(authRepositoryProvider)));
final updateUserUseCaseProvider =
    Provider((ref) => UpdateUserUseCase(ref.read(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.read(authRepositoryProvider)));
final logoutAllUseCaseProvider =
    Provider((ref) => LogoutAllUseCase(ref.read(authRepositoryProvider)));
final sendForgotPasscodeOtpUseCaseProvider = Provider(
    (ref) => SendForgotPasscodeOtpUseCase(ref.read(authRepositoryProvider)));
final verifyForgotPasscodeOtpUseCaseProvider = Provider(
    (ref) => VerifyForgotPasscodeOtpUseCase(ref.read(authRepositoryProvider)));
final resetPasscodeUseCaseProvider =
    Provider((ref) => ResetPasscodeUseCase(ref.read(authRepositoryProvider)));

// =============================================================================
// AuthNotifier
// =============================================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final CheckAuthUseCase _checkAuth;
  final LoginUseCase _login;
  final SendSignupOtpUseCase _sendOtp;
  final ResendOtpUseCase _resendOtp;
  final VerifyOtpAndRegisterUseCase _verifyAndRegister;
  final SelectTierUseCase _selectTier;
  final UpdateUserUseCase _updateUser;
  final LogoutUseCase _logout;
  final LogoutAllUseCase _logoutAll;

  AuthNotifier({
    required CheckAuthUseCase checkAuth,
    required LoginUseCase login,
    required SendSignupOtpUseCase sendOtp,
    required ResendOtpUseCase resendOtp,
    required VerifyOtpAndRegisterUseCase verifyAndRegister,
    required SelectTierUseCase selectTier,
    required UpdateUserUseCase updateUser,
    required LogoutUseCase logout,
    required LogoutAllUseCase logoutAll,
  })  : _checkAuth = checkAuth,
        _login = login,
        _sendOtp = sendOtp,
        _resendOtp = resendOtp,
        _verifyAndRegister = verifyAndRegister,
        _selectTier = selectTier,
        _updateUser = updateUser,
        _logout = logout,
        _logoutAll = logoutAll,
        super(AuthState()) {
    _restoreSession();
  }

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    state = state.loading();
    try {
      final user = await _checkAuth.call();
      if (user != null) {
        state = state.authenticated(_toModel(user), '');
      } else {
        state = state.unauthenticated();
      }
    } catch (e) {
      state = state.error('Failed to restore session. Please log in again.');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Returns the login outcome so the caller can branch. A
  /// [LoginNeedsDeviceVerification] result is not an error — credentials were
  /// accepted, but this install has to be verified before tokens are issued.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();
    try {
      final result = await _login
          .call(identifier: email, passcode: password)
          .timeout(const Duration(seconds: 30),
              onTimeout: () => throw Exception('Request timed out.'));

      switch (result) {
        case LoginSuccess(:final user):
          state = state.authenticated(_toModel(user), '');
        case LoginNeedsDeviceVerification():
          // No session yet. Left unauthenticated with a message until the
          // verify-device flow lands; the caller has the otpReference.
          state = state.unauthenticated(
            'We need to verify this device before you can sign in.',
          );
      }
      return result;
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Signup OTP ─────────────────────────────────────────────────────────────

  Future<String> sendSignupOtp({
    required String email,
    required String phoneNumber,
  }) async {
    state = state.loading();
    try {
      final otpId = await _sendOtp.call(email: email, phoneNumber: phoneNumber);
      state = state.unauthenticated('Please verify your email to continue.');
      return otpId;
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<String> resendVerification({
    required String email,
    required String phoneNumber,
  }) =>
      _resendOtp.call(email: email, phoneNumber: phoneNumber);

  // ── Verify + Register ──────────────────────────────────────────────────────

  Future<void> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
    required String confirmPasscode,
    String? referralCode,
  }) async {
    state = state.loading();
    try {
      final user = await _verifyAndRegister.call(
        otpId: otpId,
        otp: otp,
        email: email,
        phoneNumber: phoneNumber,
        passcode: passcode,
        confirmPasscode: confirmPasscode,
        referralCode: referralCode,
      );

      // register returns AuthTokenResponse and the repository has already
      // stored the tokens, so the user IS authenticated. Marking the state
      // unauthenticated here left AuthState.user null, which stranded every
      // new account on KycFlowManager's "Loading your information..." guard.
      //
      // Token is '' to match login() — AuthInterceptor reads the real token
      // from storage on every request, so AuthState.token is not load-bearing.
      state = state.authenticated(_toModel(user), '');
      debugPrint('[AuthNotifier] registered: ${user.userId}');
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Tier selection ─────────────────────────────────────────────────────────

  /// Requests [tierNumber] and returns the tier the server actually granted,
  /// which may be lower while KYC is still outstanding (the backend holds the
  /// request in `pendingTier` until then).
  Future<int> selectTier({required int tierNumber}) async {
    try {
      final user = await _selectTier.call(tierNumber: tierNumber);
      if (state.user != null) {
        final updated = state.user!.copyWith(selectedTier: user.selectedTier);
        state = state.copyWith(user: updated);
      }
      return user.selectedTier;
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Update user ────────────────────────────────────────────────────────────

  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user == null) return;
    try {
      await _updateUser.call(_fromModel(updatedUser));
      state = state.copyWith(user: updatedUser);
    } catch (_) {}
  }

  Future<void> updateKycStatus({
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
    String? bvn,
    String? nin,
  }) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(
      isBvnVerified: isBvnVerified ?? state.user!.isBvnVerified,
      isAddressVerified: isAddressVerified ?? state.user!.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? state.user!.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? state.user!.isDocumentVerified,
      bvn: bvn ?? state.user!.bvn,
      nin: nin ?? state.user!.nin,
    );
    await updateUser(updated);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _logout.call();
    state = state.unauthenticated();
  }

  Future<void> logoutAll() async {
    await _logoutAll.call();
    state = state.unauthenticated();
  }

  // ── Bridge helpers ─────────────────────────────────────────────────────────
  // Uses UserModelX extension — remove once AuthState uses UserEntity directly.

  static UserModel _toModel(UserEntity e) => UserModelX.fromEntity(e);
  static UserEntity _fromModel(UserModel m) => m.toEntity();
}

// =============================================================================
// Main provider
// =============================================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    checkAuth: ref.read(checkAuthUseCaseProvider),
    login: ref.read(loginUseCaseProvider),
    sendOtp: ref.read(sendSignupOtpUseCaseProvider),
    resendOtp: ref.read(resendOtpUseCaseProvider),
    verifyAndRegister: ref.read(verifyOtpAndRegisterUseCaseProvider),
    selectTier: ref.read(selectTierUseCaseProvider),
    updateUser: ref.read(updateUserUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
    logoutAll: ref.read(logoutAllUseCaseProvider),
  );
});

// =============================================================================
// Computed providers
// =============================================================================

final currentUserProvider =
    Provider<UserModel?>((ref) => ref.watch(authProvider).user);

final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(authProvider).isAuthenticated);

final authTokenProvider =
    Provider<String?>((ref) => ref.watch(authProvider).token);

final kycProgressProvider = Provider<double>(
    (ref) => ref.watch(currentUserProvider)?.kycProgress ?? 0.0);

final isKycCompleteProvider = Provider<bool>(
    (ref) => ref.watch(currentUserProvider)?.isKycComplete ?? false);

// ── UI state providers ────────────────────────────────────────────────────────

final pinVisibilityProvider = StateProvider<bool>((ref) => false);
final confirmPinVisibilityProvider = StateProvider<bool>((ref) => false);
final userIdProvider = StateProvider<String?>((ref) => null);
final userProvider = StateProvider<String>((ref) => '');
final userEmailProvider = StateProvider<String>((ref) => '');

final userProfileProvider = Provider<UserProfile>((ref) => UserProfile(
      userId: ref.watch(userIdProvider),
      name: ref.watch(userProvider),
      email: ref.watch(userEmailProvider),
    ));
