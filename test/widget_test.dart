// test/widget_test.dart
//
// The previous version of this file was the unmodified default
// `flutter create` counter-app smoke test — this app has no counter screen,
// so it failed unconditionally and told nobody anything real about the app.
//
// Replaced with unit tests for AuthState (this vertical slice's session
// model). Deliberately does NOT pump MyApp/SplashScreen: main.dart
// initializes camera + connectivity plugins that need platform channels
// this test environment doesn't provide, which would make a full-app pump
// flaky rather than a meaningful widget test. A real widget-level test
// belongs on an individual screen with its dependencies mocked, not here.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/user_model.dart';

void main() {
  group('AuthState', () {
    test('starts in the initial status with no user/token', () {
      final state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.token, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('loading() clears any previous error and flips isLoading', () {
      final state = AuthState().error('boom').loading();
      expect(state.status, AuthStatus.loading);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('authenticated() carries the user and token, and isAuthenticated is true',
        () {
      final user = UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
      );
      final state = AuthState().authenticated(user, 'access-token-1');

      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, same(user));
      expect(state.token, 'access-token-1');
      expect(state.errorMessage, isNull);
    });

    test('unauthenticated() clears user/token and can carry a message', () {
      final user = UserModel(userId: 'c-1', email: 'a@b.com', phoneNumber: 'x');
      final signedIn = AuthState().authenticated(user, 'access-token-1');

      final signedOut = signedIn.unauthenticated('Your session has expired.');

      expect(signedOut.status, AuthStatus.unauthenticated);
      expect(signedOut.isAuthenticated, isFalse);
      expect(signedOut.user, isNull);
      expect(signedOut.token, isNull);
      expect(signedOut.errorMessage, 'Your session has expired.');
    });

    test('error() sets hasError and preserves the message', () {
      final state = AuthState().error('Network unreachable');
      expect(state.hasError, isTrue);
      expect(state.errorMessage, 'Network unreachable');
    });
  });

  group('UserModel.fromAuthResponse', () {
    test('maps the server UserResponse shape into the local model', () {
      final user = UserModel.fromAuthResponse({
        'customerId': 'c-42',
        'fullName': 'Abraham Chidubem',
        'phoneNumber': '+2348012345678',
        'email': 'abraham@example.com',
        'tier': 'PRO',
        'pendingTier': null,
        'status': 'ACTIVE',
        'registrationComplete': true,
      });

      expect(user.userId, 'c-42');
      expect(user.name, 'Abraham Chidubem');
      expect(user.phoneNumber, '+2348012345678');
      expect(user.email, 'abraham@example.com');
      expect(user.selectedTier, 2); // PRO -> 2
      expect(user.isEmailVerified, isTrue);
      expect(user.isPhoneVerified, isTrue);
    });

    test('defaults to tier 1 (BASIC) for an unrecognised or missing tier', () {
      final user = UserModel.fromAuthResponse({
        'customerId': 'c-1',
        'phoneNumber': '+2348012345678',
        'email': 'a@b.com',
      });
      expect(user.selectedTier, 1);
    });
  });
}
