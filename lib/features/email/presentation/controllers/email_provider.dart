import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';

import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/services/email_change_services.dart';
import 'package:flutter_riverpod/legacy.dart';
// ==================== EMAIL CHANGE PROVIDER ====================

// FIXED: was constructing EmailChangeService() with no args —
// hardcoded wrong base URL and no auth token injected.
final emailChangeServiceProvider = Provider<EmailChangeService>((ref) {
  final token = ref.watch(authTokenProvider);
  return EmailChangeService(
    baseUrl: kBaseUrl,
    authToken: token,
  );
});

// Email change flow state
enum EmailChangeStep {
  initial, // Show current email
  requestingOtp, // Getting OTP
  verifyingOtp, // Entering OTP
  changingEmail, // Entering new email
  success, // Email changed successfully
}

class EmailChangeState {
  final EmailChangeStep step;
  final String? currentEmail;
  final String? maskedEmail;
  final String? verificationToken;
  final String? newEmail;
  final String? errorMessage;
  final bool isLoading;

  EmailChangeState({
    this.step = EmailChangeStep.initial,
    this.currentEmail,
    this.maskedEmail,
    this.verificationToken,
    this.newEmail,
    this.errorMessage,
    this.isLoading = false,
  });

  EmailChangeState copyWith({
    EmailChangeStep? step,
    String? currentEmail,
    String? maskedEmail,
    String? verificationToken,
    String? newEmail,
    String? errorMessage,
    bool? isLoading,
  }) {
    return EmailChangeState(
      step: step ?? this.step,
      currentEmail: currentEmail ?? this.currentEmail,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      verificationToken: verificationToken ?? this.verificationToken,
      newEmail: newEmail ?? this.newEmail,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Email change notifier
class EmailChangeNotifier extends StateNotifier<EmailChangeState> {
  final EmailChangeService _service;

  EmailChangeNotifier(this._service) : super(EmailChangeState()) {
    _loadCurrentEmail();
  }

  /// Load current user email
  Future<void> _loadCurrentEmail() async {
    final email = await _service.getCurrentEmail();
    if (email != null) {
      state = state.copyWith(
        currentEmail: email,
        maskedEmail: _service.maskEmail(email),
      );
    }
  }

  /// Request OTP for email change
  Future<bool> requestOTP() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.requestOTP(state.currentEmail ?? '');

      if (result['success'] == true) {
        state = state.copyWith(
          step: EmailChangeStep.verifyingOtp,
          maskedEmail: result['maskedEmail'] as String? ?? state.maskedEmail,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to request OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.verifyOTP(otp);

      if (result['success'] == true) {
        state = state.copyWith(
          step: EmailChangeStep.changingEmail,
          verificationToken: result['verificationToken'] as String?,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to verify OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Change email address
  Future<bool> changeEmail(String newEmail) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.changeEmail(
        newEmail: newEmail,
        verificationToken: state.verificationToken ?? '',
      );

      if (result['success'] == true) {
        state = state.copyWith(
          step: EmailChangeStep.success,
          newEmail: result['newEmail'] as String?,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to change email: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOTP() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.resendOTP();

      state = state.copyWith(isLoading: false);

      if (result['success'] == true) {
        return true;
      } else {
        state = state.copyWith(errorMessage: result['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to resend OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = EmailChangeState(
      currentEmail: state.currentEmail,
      maskedEmail: state.maskedEmail,
    );
  }

  /// Go back to previous step
  void goBack() {
    switch (state.step) {
      case EmailChangeStep.verifyingOtp:
        state = state.copyWith(step: EmailChangeStep.initial);
        break;
      case EmailChangeStep.changingEmail:
        state = state.copyWith(step: EmailChangeStep.verifyingOtp);
        break;
      default:
        break;
    }
  }
}

// Provider for email change
final emailChangeProvider =
    StateNotifierProvider<EmailChangeNotifier, EmailChangeState>((ref) {
  final service = ref.watch(emailChangeServiceProvider);
  return EmailChangeNotifier(service);
});
