// lib/provider/auth/registration_flow_provider.dart
//
// Carries in-progress signup data across the 3-screen registration flow
// (SignUpScreen -> EmailVerifySignup -> KnowYouBetterForm).
//
// The backend's register() call only fires at the very end of the flow —
// after OTP verification (step 2) and referral-code collection (step 3,
// which is where the recent auth-service work on referral normalization
// applies) — but phone/email/passcode/fullName are collected on screen 1
// and the otpReference is only known after screen 2. This holds that data
// in one place instead of threading it through constructor params across
// three widgets.

import 'package:flutter_riverpod/legacy.dart';

class RegistrationFlowData {
  final String? phoneNumber;
  final String? email;
  final String? passcode;
  final String? fullName;
  final String? otpReference;

  const RegistrationFlowData({
    this.phoneNumber,
    this.email,
    this.passcode,
    this.fullName,
    this.otpReference,
  });

  // fullName deliberately excluded — the PRD's registration step collects
  // only phone/email/passcode (see signup.dart); fullName is not part of
  // this app's registration data model. See the auth-service backend
  // advisory: RegisterRequest.fullName is currently @NotBlank server-side,
  // which conflicts with this and blocks registration until fixed there.
  bool get hasBasicInfo =>
      phoneNumber != null && email != null && passcode != null;

  RegistrationFlowData copyWith({
    String? phoneNumber,
    String? email,
    String? passcode,
    String? fullName,
    String? otpReference,
  }) {
    return RegistrationFlowData(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      passcode: passcode ?? this.passcode,
      fullName: fullName ?? this.fullName,
      otpReference: otpReference ?? this.otpReference,
    );
  }
}

class RegistrationFlowNotifier extends StateNotifier<RegistrationFlowData> {
  RegistrationFlowNotifier() : super(const RegistrationFlowData());

  void setBasicInfo({
    required String phoneNumber,
    required String email,
    required String passcode,
  //  required String fullName,
  }) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      email: email,
      passcode: passcode,
 //     fullName: fullName,
    );
  }

  void setOtpReference(String otpReference) {
    state = state.copyWith(otpReference: otpReference);
  }

  /// Resets the flow — call after a successful register(), or if the user
  /// backs out of signup entirely.
  void clear() {
    state = const RegistrationFlowData();
  }
}

final registrationFlowProvider =
    StateNotifierProvider<RegistrationFlowNotifier, RegistrationFlowData>(
  (ref) => RegistrationFlowNotifier(),
);
