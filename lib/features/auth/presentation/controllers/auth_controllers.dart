// lib/features/auth/presentation/controllers/auth_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/features/auth/data/auth_services.dart';
import 'package:kudipay/features/auth/domain/repositories/auth_repositories.dart';

import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kudipay/features/auth/domain/usecases/auth_usecases.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/model/user/user_model_extension.dart';
import '../../domain/auth_state.dart';
import '../../domain/entities/user_entities.dart';

export 'package:kudipay/model/auth/auth_state.dart';

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
final completeOnboardingUseCaseProvider = Provider(
    (ref) => CompleteOnboardingUseCase(ref.read(authRepositoryProvider)));
final updateUserUseCaseProvider =
    Provider((ref) => UpdateUserUseCase(ref.read(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.read(authRepositoryProvider)));

// =============================================================================
// AuthNotifier
// =============================================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final CheckAuthUseCase _checkAuth;
  final LoginUseCase _login;
  final SendSignupOtpUseCase _sendOtp;
  final ResendOtpUseCase _resendOtp;
  final VerifyOtpAndRegisterUseCase _verifyAndRegister;
  final CompleteOnboardingUseCase _completeOnboarding;
  final UpdateUserUseCase _updateUser;
  final LogoutUseCase _logout;

  AuthNotifier({
    required CheckAuthUseCase checkAuth,
    required LoginUseCase login,
    required SendSignupOtpUseCase sendOtp,
    required ResendOtpUseCase resendOtp,
    required VerifyOtpAndRegisterUseCase verifyAndRegister,
    required CompleteOnboardingUseCase completeOnboarding,
    required UpdateUserUseCase updateUser,
    required LogoutUseCase logout,
  })  : _checkAuth = checkAuth,
        _login = login,
        _sendOtp = sendOtp,
        _resendOtp = resendOtp,
        _verifyAndRegister = verifyAndRegister,
        _completeOnboarding = completeOnboarding,
        _updateUser = updateUser,
        _logout = logout,
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

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();
    try {
      final user = await _login
          .call(identifier: email, passcode: password)
          .timeout(const Duration(seconds: 30),
              onTimeout: () => throw Exception('Request timed out.'));
      state = state.authenticated(_toModel(user), '');
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
  }) async {
    state = state.loading();
    try {
      final user = await _verifyAndRegister.call(
        otpId: otpId,
        otp: otp,
        email: email,
        phoneNumber: phoneNumber,
        passcode: passcode,
      );
      state =
          state.unauthenticated('Registration successful. Please continue.');
      debugPrint('[AuthNotifier] registered: ${user.userId}');
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  Future<void> completeOnboarding({required int tierNumber}) async {
    try {
      await _completeOnboarding.call(tierNumber: tierNumber);
      if (state.user != null) {
        final updated = state.user!.copyWith(selectedTier: tierNumber);
        state = state.copyWith(user: updated);
      }
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
    completeOnboarding: ref.read(completeOnboardingUseCaseProvider),
    updateUser: ref.read(updateUserUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
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
