import 'package:kudipay/model/user/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// The 202 `deviceVerificationRequired` challenge returned by
/// `POST /auth/login` when the login came from a device whose
/// `deviceFingerprint` is not yet trusted for the account. The auth-service
/// has ALREADY dispatched a DEVICE_LINK OTP at that point; the client must
/// collect it via `/auth/verify-otp` and then complete the login with
/// `/auth/login/verify-device`.
class DeviceVerificationChallenge {
  final String otpReference;
  final String maskedIdentifier;
  final int expiresInSeconds;

  const DeviceVerificationChallenge({
    required this.otpReference,
    required this.maskedIdentifier,
    required this.expiresInSeconds,
  });
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final DeviceVerificationChallenge? deviceChallenge;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.deviceChallenge,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
  bool get requiresDeviceVerification => deviceChallenge != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
    DeviceVerificationChallenge? deviceChallenge,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      deviceChallenge: deviceChallenge ?? this.deviceChallenge,
    );
  }

  // Create a loading state.
  // Deliberately NOT built via copyWith(): copyWith's `errorMessage ??
  // this.errorMessage` treats an explicit `null` as "unspecified" and falls
  // back to the old value, so a stale error would otherwise survive into
  // the loading state and could flash alongside a loading spinner.
  AuthState loading() {
    return AuthState(
      status: AuthStatus.loading,
      user: user,
      token: token,
      errorMessage: null,
    );
  }

  // Create an authenticated state
  AuthState authenticated(UserModel user, String token) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: token,
      errorMessage: null,
    );
  }

  // Create an unauthenticated state
  AuthState unauthenticated([String? message]) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
      errorMessage: message,
    );
  }

  // Create a device-verification-required state (202 DEVICE_LINK challenge).
  // Not a session and not an error: the login response told us this device
  // isn't trusted yet and a DEVICE_LINK OTP is already on its way to the
  // account identifier. status stays unauthenticated — only
  // completeSession() (after /auth/login/verify-device) may flip it.
  AuthState deviceVerificationRequired(DeviceVerificationChallenge challenge) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
      errorMessage: null,
      deviceChallenge: challenge,
    );
  }

  // Create an error state
  AuthState error(String message) {
    return copyWith(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}