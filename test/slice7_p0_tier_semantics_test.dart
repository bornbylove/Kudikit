// test/slice7_p0_tier_semantics_test.dart
//
// Slice 7 P0-3 + P0-2: granted-vs-pending/null tier semantics and login-gate
// routing. Guards:
//   * A null granted tier is UNVERIFIED (never fabricated into Tier 1).
//   * pendingTier / selectedTier / local state are routing intent, never the
//     granted tier.
//   * Granted Basic/Pro/Mega tiers map to 1/2/3 and display correctly.
//   * A user with no liveness routes through the KYC funnel (continueFunnel),
//     never straight to the dashboard (complete).

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';

UserModel _user({
  int selectedTier = 1,
  int? pendingTier,
  int? grantedTier,
  KycStatus kycStatus = KycStatus.notStarted,
  bool isSelfieVerified = false,
  bool isBvnVerified = false,
  bool isNinVerified = false,
  IdDocumentStatus idDocumentStatus = IdDocumentStatus.notStarted,
  AddressVerificationStatus addressStatus =
      AddressVerificationStatus.notStarted,
}) {
  return UserModel(
    userId: 'c-1',
    email: 'a@b.com',
    phoneNumber: '+2348012345678',
    selectedTier: selectedTier,
    pendingTier: pendingTier,
    grantedTier: grantedTier,
    kycStatus: kycStatus,
    isSelfieVerified: isSelfieVerified,
    isBvnVerified: isBvnVerified,
    isNinVerified: isNinVerified,
    idDocumentStatus: idDocumentStatus,
    addressStatus: addressStatus,
  );
}

Map<String, dynamic> _authResponse({
  String? tier,
  String? pendingTier,
  Map<String, dynamic>? kyc,
}) {
  return {
    'customerId': 'KDT-CUST1',
    'email': 'a@b.com',
    'phoneNumber': '+2348012345678',
    'fullName': 'Jane Doe',
    'tier': tier,
    'pendingTier': pendingTier,
    if (kyc != null) 'kyc': kyc,
  };
}

void main() {
  group('UserModel.grantedTier — null must not become Tier 1 (P0-3)', () {
    test('auth response with tier null → UNVERIFIED (0), not Basic', () {
      final user = UserModel.fromAuthResponse(_authResponse(tier: null));
      expect(user.grantedTier, isNull);
      expect(user.grantedTierOrZero, 0);
      expect(user.hasGrantedTier, isFalse);
    });

    test('auth response with BASIC → granted tier 1', () {
      final user = UserModel.fromAuthResponse(_authResponse(tier: 'BASIC'));
      expect(user.grantedTier, 1);
      expect(user.grantedTierOrZero, 1);
      expect(user.hasGrantedTier, isTrue);
    });

    test('auth response with PRO → granted tier 2', () {
      final user = UserModel.fromAuthResponse(_authResponse(tier: 'PRO'));
      expect(user.grantedTier, 2);
      expect(user.hasGrantedTier, isTrue);
    });

    test('auth response with MEGA → granted tier 3', () {
      final user = UserModel.fromAuthResponse(_authResponse(tier: 'MEGA'));
      expect(user.grantedTier, 3);
      expect(user.hasGrantedTier, isTrue);
    });

    test('pendingTier is distinct from grantedTier — a pending upgrade is NOT '
        'a grant', () {
      // User selected Pro (pendingTier=PRO) but nothing has been granted yet.
      final user = UserModel.fromAuthResponse(
        _authResponse(tier: null, pendingTier: 'PRO'),
      );
      expect(user.pendingTier, 2);
      expect(user.grantedTier, isNull);
      expect(user.grantedTierOrZero, 0,
          reason: 'pendingTier must not be displayed as the granted tier');
    });

    test('a locally-selected tier does not become the granted tier', () {
      // selectedTier is local routing intent (defaults to 1); grantedTier comes
      // only from the server `tier` field.
      final user = _user(selectedTier: 2, grantedTier: null);
      expect(user.selectedTier, 2);
      expect(user.grantedTierOrZero, 0);
      expect(user.hasGrantedTier, isFalse);
    });

    test('granted tier survives a JSON round-trip', () {
      final user = _user(grantedTier: 2);
      final restored = UserModel.fromJson(user.toJson());
      expect(restored.grantedTier, 2);
      expect(restored.grantedTierOrZero, 2);
    });

    test('granted tier survives copyWith and defaults to null for a fresh user',
        () {
      expect(_user().grantedTier, isNull);
      expect(_user().grantedTierOrZero, 0);
      final u = _user().copyWith(grantedTier: 3);
      expect(u.grantedTier, 3);
      expect(u.grantedTierOrZero, 3);
    });

    test('granted tier is parsed independently of KYC booleans', () {
      // A user with liveness verified but no server grant is still UNVERIFIED.
      final user = UserModel.fromAuthResponse(
        _authResponse(
          tier: null,
          kyc: {
            'status': 'IN_PROGRESS',
            'livenessVerified': true,
            'bvnVerified': false,
            'ninVerified': false,
          },
        ),
      );
      expect(user.isSelfieVerified, isTrue);
      expect(user.grantedTier, isNull);
      expect(user.grantedTierOrZero, 0);
    });
  });

  group('Login gate routing — no liveness means no dashboard (P0-2)', () {
    test('a user with no liveness routes to the funnel, never complete', () {
      final user = _user(
        kycStatus: KycStatus.pending,
        grantedTier: null,
      );
      final decision = KycFlowManager.classify(TierLevel.basic, user);
      expect(decision, KycRoutingDecision.continueFunnel);
      expect(decision, isNot(KycRoutingDecision.complete));
    });

    test('a user with no liveness and no grant is not Basic-complete', () {
      // Even though selectedTier defaults to 1 and the user appears "Tier 1",
      // the routing decision must NOT be complete until the PRD gate passes.
      final user = _user(
        selectedTier: 1,
        grantedTier: null,
        isBvnVerified: true,
        kycStatus: KycStatus.inProgress,
      );
      expect(
        KycFlowManager.classify(TierLevel.basic, user),
        KycRoutingDecision.continueFunnel,
        reason: 'BVN without selfie must not complete Basic',
      );
    });

    test('a granted Basic user with selfie + NIN-only routes to the dashboard '
        '(Slice 6 PRD gate retained)', () {
      final user = _user(
        grantedTier: 1,
        isSelfieVerified: true,
        isNinVerified: true,
      );
      expect(
        KycFlowManager.classify(TierLevel.basic, user),
        KycRoutingDecision.complete,
        reason: 'NIN-only satisfies Basic (PRD: BVN OR NIN)',
      );
    });

    test('a granted Pro user with BVN+NIN+ID routes to the dashboard', () {
      final user = _user(
        grantedTier: 2,
        isSelfieVerified: true,
        isBvnVerified: true,
        isNinVerified: true,
        idDocumentStatus: IdDocumentStatus.verified,
      );
      expect(
        KycFlowManager.classify(TierLevel.pro, user),
        KycRoutingDecision.complete,
      );
    });

    test('a granted Mega user with verified address routes to the dashboard', () {
      final user = _user(
        grantedTier: 3,
        isSelfieVerified: true,
        isBvnVerified: true,
        isNinVerified: true,
        idDocumentStatus: IdDocumentStatus.verified,
        addressStatus: AddressVerificationStatus.verified,
      );
      expect(
        KycFlowManager.classify(TierLevel.mega, user),
        KycRoutingDecision.complete,
      );
    });

    test('effectiveTier keeps routing intent separate from the granted tier',
        () {
      // Routing tier is the tier being worked toward; grantedTier stays null.
      final user = _user(pendingTier: 3, grantedTier: null);
      expect(KycFlowManager.effectiveTier(user, TierLevel.basic),
          TierLevel.mega);
      expect(user.grantedTier, isNull);
      expect(user.grantedTierOrZero, 0);
    });

    test('tier upgrade status is carried internally and survives a JSON '
        'round-trip (backend MEGA review lifecycle)', () {
      final user = _user(
        pendingTier: 3,
        grantedTier: 2,
        kycStatus: KycStatus.pending,
      ).copyWith(
        tierUpgradeStatus: TierUpgradeStatus.reviewing,
        tierUpgradeReviewNotes: 'address confirmed, awaiting decision',
      );

      expect(user.tierUpgradeStatus, TierUpgradeStatus.reviewing);
      expect(user.grantedTierOrZero, 2, reason: 'KYC stays at tier 2 while '
          'the MEGA request awaits admin review');

      final restored = UserModel.fromJson(user.toJson());
      expect(restored.tierUpgradeStatus, TierUpgradeStatus.reviewing);
      expect(restored.tierUpgradeReviewNotes,
          'address confirmed, awaiting decision');

      // copyWithKyc folds the server summary (incl. the lifecycle) into the model.
      final fromSummary = _user().copyWithKyc(KycStatusSummary(
        status: KycStatus.pending,
        tierUpgradeStatus: TierUpgradeStatus.submitted,
        tierUpgradeReviewNotes: 'pending agent visit',
      ));
      expect(fromSummary.tierUpgradeStatus, TierUpgradeStatus.submitted);
      expect(fromSummary.tierUpgradeReviewNotes, 'pending agent visit');
    });
  });
}