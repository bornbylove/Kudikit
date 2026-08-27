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
import 'package:kudipay/model/user/kyc_status.dart';
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

  group('UserModel KYC parsing (Slice 4B)', () {
    Map<String, dynamic> userJson({
      Map<String, dynamic>? kyc,
      String? status,
      bool? registrationComplete,
      Object? pendingTier,
    }) {
      return {
        'customerId': 'c-42',
        'fullName': 'Abraham Chidubem',
        'phoneNumber': '+2348012345678',
        'email': 'abraham@example.com',
        'tier': 'PRO',
        if (kyc != null) 'kyc': kyc,
        if (status != null) 'status': status,
        if (registrationComplete != null)
          'registrationComplete': registrationComplete,
        if (pendingTier != null) 'pendingTier': pendingTier,
      };
    }

    test('maps a VERIFIED server KYC summary into typed fields and derives '
        'the convenience booleans', () {
      final user = UserModel.fromAuthResponse(userJson(kyc: {
        'status': 'VERIFIED',
        'bvnVerified': true,
        'ninVerified': true,
        'livenessVerified': true,
        'idDocumentStatus': 'VERIFIED',
        'addressStatus': 'VERIFIED',
        'requiresManualReview': false,
      }));

      expect(user.kycStatus, KycStatus.verified);
      expect(user.idDocumentStatus, IdDocumentStatus.verified);
      expect(user.addressStatus, AddressVerificationStatus.verified);
      expect(user.requiresManualReview, isFalse);
      expect(user.isNinVerified, isTrue);
      // Convenience booleans are derived from the authoritative typed state.
      expect(user.isBvnVerified, isTrue);
      expect(user.isSelfieVerified, isTrue);
      expect(user.isDocumentVerified, isTrue);
      expect(user.isAddressVerified, isTrue);
      // Authoritative completion gate: VERIFIED only.
      expect(user.isKycComplete, isTrue);
    });

    test('every non-verified top-level status parses without collapsing into '
        'NOT_STARTED and does NOT complete KYC', () {
      const statuses = {
        'PENDING': KycStatus.pending,
        'IN_PROGRESS': KycStatus.inProgress,
        'MANUAL_REVIEW': KycStatus.manualReview,
        'REJECTED': KycStatus.rejected,
        'EXPIRED': KycStatus.expired,
      };
      statuses.forEach((wire, expected) {
        final user = UserModel.fromAuthResponse(
            userJson(kyc: {'status': wire}));
        expect(user.kycStatus, expected, reason: 'kyc.status=$wire');
        expect(user.isKycComplete, isFalse, reason: 'kyc.status=$wire');
      });
    });

    test('multi-state idDocumentStatus and addressStatus stay distinguishable',
        () {
      final user = UserModel.fromAuthResponse(userJson(kyc: {
        'status': 'IN_PROGRESS',
        'bvnVerified': true,
        'idDocumentStatus': 'MANUAL_REVIEW',
        'addressStatus': 'PENDING_AGENT_VISIT',
      }));

      expect(user.idDocumentStatus, IdDocumentStatus.manualReview);
      expect(user.addressStatus, AddressVerificationStatus.pendingAgentVisit);
      // Convenience booleans reflect only the authoritative VERIFIED states.
      expect(user.isDocumentVerified, isFalse);
      expect(user.isAddressVerified, isFalse);
    });

    test('with NO server KYC summary, cached KYC state is preserved (refresh '
        'merge)', () {
      final cached = UserModel(
        userId: 'c-42',
        email: 'abraham@example.com',
        phoneNumber: '+2348012345678',
        isSelfieVerified: true,
        isBvnVerified: true,
        kycStatus: KycStatus.inProgress,
        idDocumentStatus: IdDocumentStatus.notStarted,
        addressStatus: AddressVerificationStatus.notStarted,
      );

      final refreshed = UserModel.fromAuthResponse(
        userJson(), // no `kyc` key
        existing: cached,
      );

      expect(refreshed.isSelfieVerified, isTrue);
      expect(refreshed.isBvnVerified, isTrue);
      expect(refreshed.kycStatus, KycStatus.inProgress);
      expect(refreshed.name, 'Abraham Chidubem');
    });

    test('server KYC present OVERRIDES cached local KYC state wholesale',
        () {
      final cached = UserModel(
        userId: 'c-42',
        email: 'abraham@example.com',
        phoneNumber: '+2348012345678',
        isSelfieVerified: true,
        isBvnVerified: true,
        isDocumentVerified: true,
        isAddressVerified: true,
        kycStatus: KycStatus.verified,
      );

      final refreshed = UserModel.fromAuthResponse(
        userJson(kyc: {
          'status': 'NOT_STARTED',
          'bvnVerified': false,
          'livenessVerified': false,
          'idDocumentStatus': 'NOT_STARTED',
          'addressStatus': 'NOT_STARTED',
        }),
        existing: cached,
      );

      // Stale cached booleans/typed state are NEVER preserved over server KYC.
      expect(refreshed.kycStatus, KycStatus.notStarted);
      expect(refreshed.isSelfieVerified, isFalse);
      expect(refreshed.isBvnVerified, isFalse);
      expect(refreshed.isDocumentVerified, isFalse);
      expect(refreshed.isAddressVerified, isFalse);
      expect(refreshed.isKycComplete, isFalse);
    });

    test('parses userStatus, registrationComplete and pendingTier', () {
      final user = UserModel.fromAuthResponse(userJson(
        status: 'ACTIVE',
        registrationComplete: true,
        pendingTier: 'MEGA',
      ));

      expect(user.userStatus, UserStatus.active);
      expect(user.registrationComplete, isTrue);
      expect(user.pendingTier, 3); // MEGA -> 3
    });

    test('isKycComplete is ONLY true when the top-level status is VERIFIED', () {
      final allBooleansButNotVerified = UserModel.fromAuthResponse(userJson(kyc: {
        'status': 'IN_PROGRESS',
        'bvnVerified': true,
        'ninVerified': true,
        'livenessVerified': true,
        'idDocumentStatus': 'VERIFIED',
        'addressStatus': 'VERIFIED',
      }));
      expect(allBooleansButNotVerified.isBvnVerified, isTrue);
      expect(allBooleansButNotVerified.isDocumentVerified, isTrue);
      expect(allBooleansButNotVerified.isAddressVerified, isTrue);
      expect(allBooleansButNotVerified.isKycComplete, isFalse,
          reason: 'derived booleans are NOT authoritative for completion');
    });

    test('old cached JSON without kyc fields still deserializes to safe '
        'defaults', () {
      final user = UserModel.fromJson({
        'userId': 'c-1',
        'email': 'a@b.com',
        'phoneNumber': '+2348012345678',
        'isBvnVerified': true,
      });

      expect(user.kycStatus, KycStatus.notStarted);
      expect(user.idDocumentStatus, IdDocumentStatus.notStarted);
      expect(user.addressStatus, AddressVerificationStatus.notStarted);
      expect(user.requiresManualReview, isFalse);
      expect(user.isNinVerified, isFalse);
      expect(user.userStatus, isNull);
      expect(user.registrationComplete, isFalse);
      expect(user.pendingTier, isNull);
      // Legacy boolean still reads back.
      expect(user.isBvnVerified, isTrue);
    });

    test('toJson/fromJson round-trips the typed KYC fields', () {
      final original = UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
        kycStatus: KycStatus.manualReview,
        idDocumentStatus: IdDocumentStatus.rejected,
        addressStatus: AddressVerificationStatus.pendingAgentVisit,
        requiresManualReview: true,
        isNinVerified: true,
        userStatus: UserStatus.active,
        registrationComplete: true,
        pendingTier: 2,
      );

      final restored = UserModel.fromJson(original.toJson());

      expect(restored.kycStatus, KycStatus.manualReview);
      expect(restored.idDocumentStatus, IdDocumentStatus.rejected);
      expect(restored.addressStatus,
          AddressVerificationStatus.pendingAgentVisit);
      expect(restored.requiresManualReview, isTrue);
      expect(restored.isNinVerified, isTrue);
      expect(restored.userStatus, UserStatus.active);
      expect(restored.registrationComplete, isTrue);
      expect(restored.pendingTier, 2);
    });

    test('copyWithKyc applies the server summary wholesale and preserves '
        'identity fields', () {
      final user = UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
        name: 'Old Name',
        isSelfieVerified: true,
        isBvnVerified: true,
        kycStatus: KycStatus.verified,
      );

      final merged = user.copyWithKyc(const KycStatusSummary(
        status: KycStatus.pending,
        bvnVerified: false,
        ninVerified: false,
        livenessVerified: false,
        idDocumentStatus: IdDocumentStatus.manualReview,
        addressStatus: AddressVerificationStatus.notStarted,
        requiresManualReview: true,
      ));

      // Server wins over cached KYC state…
      expect(merged.kycStatus, KycStatus.pending);
      expect(merged.isBvnVerified, isFalse);
      expect(merged.isSelfieVerified, isFalse);
      expect(merged.idDocumentStatus, IdDocumentStatus.manualReview);
      expect(merged.requiresManualReview, isTrue);
      // …while identity/persistence fields are untouched.
      expect(merged.userId, 'c-1');
      expect(merged.name, 'Old Name');
      expect(merged.email, 'a@b.com');
    });
  });
}
