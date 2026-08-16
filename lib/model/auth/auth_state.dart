import 'package:kudipay/model/user/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
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

  // Create an error state
  AuthState error(String message) {
    return copyWith(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}