// test/kyc_flow_manager_test.dart
//
// Slice 4B + Slice 6: KycFlowManager routing on server-authoritative typed KYC
// state. NOT_STARTED / IN_PROGRESS continue the frozen funnel; completion is
// evaluated PER TIER against the PRD requirements (top-level KycStatus VERIFIED
// only means BVN-or-NIN, NOT Pro/Mega completion); PENDING_AGENT_VISIT on a
// Mega target is the PRD interim tier (dashboard on Tier-2 limits);
// MANUAL_REVIEW / REJECTED / EXPIRED hold for the minimal status surface with
// the server reason + refresh/retry. Pure unit tests on the static classifier —
// no widget pumping required.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';

void main() {
  UserModel user({
    KycStatus kycStatus = KycStatus.notStarted,
    IdDocumentStatus idDocumentStatus = IdDocumentStatus.notStarted,
    AddressVerificationStatus addressStatus =
        AddressVerificationStatus.notStarted,
    bool isSelfieVerified = false,
    bool isBvnVerified = false,
    bool isNinVerified = false,
    bool isDocumentVerified = false,
    bool isAddressVerified = false,
    int selectedTier = 1,
    int? pendingTier,
    String? rejectionReason,
    String? idDocumentRejectionReason,
    String? addressRejectionReason,
  }) {
    return UserModel(
      userId: 'c-1',
      email: 'a@b.com',
      phoneNumber: '+2348012345678',
      kycStatus: kycStatus,
      idDocumentStatus: idDocumentStatus,
      addressStatus: addressStatus,
      isSelfieVerified: isSelfieVerified,
      isBvnVerified: isBvnVerified,
      isNinVerified: isNinVerified,
      isDocumentVerified: isDocumentVerified,
      isAddressVerified: isAddressVerified,
      selectedTier: selectedTier,
      pendingTier: pendingTier,
      rejectionReason: rejectionReason,
      idDocumentRejectionReason: idDocumentRejectionReason,
      addressRejectionReason: addressRejectionReason,
    );
  }

  group('KycFlowManager.effectiveTier (Slice 6 — server-authoritative)', () {
    test('pendingTier (server select-tier) wins over selectedTier and fallback',
        () {
      expect(
        KycFlowManager.effectiveTier(
            user(selectedTier: 1, pendingTier: 3), TierLevel.basic),
        TierLevel.mega,
      );
    });

    test('selectedTier is used when no pendingTier is set', () {
      expect(
        KycFlowManager.effectiveTier(user(selectedTier: 2), TierLevel.basic),
        TierLevel.pro,
      );
    });

    test('falls back to the local tier provider for legacy/cached users', () {
      // selectedTier 0 is out of the 1..3 range → provider fallback applies.
      expect(
        KycFlowManager.effectiveTier(user(selectedTier: 0), TierLevel.pro),
        TierLevel.pro,
      );
    });
  });

  group('KycFlowManager.classify — funnel states', () {
    test('NOT_STARTED continues the existing funnel on every tier', () {
      for (final tier in TierLevel.values) {
        expect(KycFlowManager.classify(tier, user()),
            KycRoutingDecision.continueFunnel,
            reason: 'NOT_STARTED on $tier');
      }
    });

    test('IN_PROGRESS resumes the existing funnel on every tier', () {
      for (final tier in TierLevel.values) {
        expect(
            KycFlowManager.classify(tier, user(kycStatus: KycStatus.inProgress)),
            KycRoutingDecision.continueFunnel,
            reason: 'IN_PROGRESS on $tier');
      }
    });

    test('PENDING with no verification activity is startable (Slice 5 — the '
        'getOrCreate() artifact)', () {
      for (final tier in TierLevel.values) {
        expect(
          KycFlowManager.classify(tier, user(kycStatus: KycStatus.pending)),
          KycRoutingDecision.continueFunnel,
          reason: 'fresh PENDING on $tier',
        );
      }
    });

    test('PENDING with verification activity resumes at the first incomplete '
        'step rather than holding', () {
      for (final tier in TierLevel.values) {
        expect(
          KycFlowManager.classify(
              tier,
              user(
                kycStatus: KycStatus.pending,
                isBvnVerified: true,
              )),
          KycRoutingDecision.continueFunnel,
          reason: 'in-flight PENDING on $tier',
        );
      }
    });
  });

  group('KycFlowManager.classify — PRD per-tier completion (Slice 6)', () {
    test('Basic is complete with selfie + (BVN OR NIN)', () {
      expect(
        KycFlowManager.classify(
            TierLevel.basic,
            user(isSelfieVerified: true, isBvnVerified: true, isNinVerified: false)),
        KycRoutingDecision.complete,
      );
      expect(
        KycFlowManager.classify(
            TierLevel.basic,
            user(isSelfieVerified: true, isBvnVerified: false, isNinVerified: true)),
        KycRoutingDecision.complete,
        reason: 'NIN-only satisfies Basic (PRD: BVN OR NIN)',
      );
    });

    test('Basic is NOT complete with only one of BVN/NIN unverified or no '
        'selfie', () {
      expect(
        KycFlowManager.classify(
            TierLevel.basic, user(isSelfieVerified: true)),
        KycRoutingDecision.continueFunnel,
        reason: 'no BVN and no NIN',
      );
      expect(
        KycFlowManager.classify(
            TierLevel.basic, user(isBvnVerified: true)),
        KycRoutingDecision.continueFunnel,
        reason: 'no selfie',
      );
    });

    test('Pro requires selfie + BVN AND NIN + ID document', () {
      final pro = user(
        isSelfieVerified: true,
        isBvnVerified: true,
        isNinVerified: true,
        idDocumentStatus: IdDocumentStatus.verified,
      );
      expect(
        KycFlowManager.classify(TierLevel.pro, pro),
        KycRoutingDecision.complete,
      );
      // BVN only is NOT enough for Pro.
      expect(
        KycFlowManager.classify(
            TierLevel.pro,
            user(
              isSelfieVerified: true,
              isBvnVerified: true,
              idDocumentStatus: IdDocumentStatus.verified,
            )),
        KycRoutingDecision.continueFunnel,
      );
      // ID document missing.
      expect(
        KycFlowManager.classify(
            TierLevel.pro,
            user(
              isSelfieVerified: true,
              isBvnVerified: true,
              isNinVerified: true,
            )),
        KycRoutingDecision.continueFunnel,
      );
    });

    test('Mega requires selfie + BVN AND NIN + ID + address verified', () {
      final mega = user(
        isSelfieVerified: true,
        isBvnVerified: true,
        isNinVerified: true,
        idDocumentStatus: IdDocumentStatus.verified,
        addressStatus: AddressVerificationStatus.verified,
      );
      expect(
        KycFlowManager.classify(TierLevel.mega, mega),
        KycRoutingDecision.complete,
      );
      // Address not verified yet → funnel to address step.
      expect(
        KycFlowManager.classify(
            TierLevel.mega,
            user(
              isSelfieVerified: true,
              isBvnVerified: true,
              isNinVerified: true,
              idDocumentStatus: IdDocumentStatus.verified,
            )),
        KycRoutingDecision.continueFunnel,
      );
    });

    test('Mega PENDING_AGENT_VISIT is the PRD interim tier → dashboard', () {
      // Pro is complete and the address agent visit is in flight: user belongs
      // on the dashboard on Tier-2 limits, never a dead loading screen.
      expect(
        KycFlowManager.classify(
            TierLevel.mega,
            user(
              kycStatus: KycStatus.inProgress,
              isSelfieVerified: true,
              isBvnVerified: true,
              isNinVerified: true,
              idDocumentStatus: IdDocumentStatus.verified,
              addressStatus: AddressVerificationStatus.pendingAgentVisit,
            )),
        KycRoutingDecision.complete,
      );
    });

    test('PENDING_AGENT_VISIT never blocks Basic/Pro completion', () {
      // Address is out of scope for Basic/Pro: once their own PRD requirements
      // are met they are complete even while the agent visit is in flight...
      for (final tier in [TierLevel.basic, TierLevel.pro]) {
        expect(
          KycFlowManager.classify(
              tier,
              user(
                kycStatus: KycStatus.inProgress,
                isSelfieVerified: true,
                isBvnVerified: true,
                isNinVerified: true,
                idDocumentStatus: IdDocumentStatus.verified,
                addressStatus: AddressVerificationStatus.pendingAgentVisit,
              )),
          KycRoutingDecision.complete,
          reason: 'address in flight but $tier requirements met',
        );
      }
      // ...and when their own requirements are unmet, the funnel resumes rather
      // than holding on the address status.
      expect(
        KycFlowManager.classify(
            TierLevel.basic,
            user(
              kycStatus: KycStatus.inProgress,
              isSelfieVerified: false,
              addressStatus: AddressVerificationStatus.pendingAgentVisit,
            )),
        KycRoutingDecision.continueFunnel,
      );
    });

    test('top-level VERIFIED is NOT Pro/Mega completion without the PRD '
        'requirements (Slice 6 correction)', () {
      // The auth-service flips top-level KycStatus to VERIFIED after just BVN
      // or NIN — it must NOT short-circuit Pro/Mega to the dashboard.
      expect(
        KycFlowManager.classify(
            TierLevel.pro,
            user(
              kycStatus: KycStatus.verified,
              isBvnVerified: true,
              isNinVerified: false,
            )),
        KycRoutingDecision.continueFunnel,
      );
      expect(
        KycFlowManager.classify(
            TierLevel.mega,
            user(
              kycStatus: KycStatus.verified,
              isBvnVerified: true,
              isNinVerified: true,
              idDocumentStatus: IdDocumentStatus.verified,
              addressStatus: AddressVerificationStatus.notStarted,
            )),
        KycRoutingDecision.continueFunnel,
      );
    });
  });

  group('KycFlowManager.classify — async hold states', () {
    test('MANUAL_REVIEW / REJECTED / EXPIRED hold on every tier', () {
      const reviewStates = {
        KycStatus.manualReview,
        KycStatus.rejected,
        KycStatus.expired,
      };
      for (final status in reviewStates) {
        for (final tier in TierLevel.values) {
          expect(
            KycFlowManager.classify(tier, user(kycStatus: status)),
            KycRoutingDecision.holdForUiApproval,
            reason: '$status on $tier',
          );
        }
      }
    });

    test('ID document MANUAL_REVIEW / REJECTED hold', () {
      for (final tier in TierLevel.values) {
        expect(
          KycFlowManager.classify(
              tier,
              user(
                kycStatus: KycStatus.inProgress,
                idDocumentStatus: IdDocumentStatus.manualReview,
              )),
          KycRoutingDecision.holdForUiApproval,
          reason: 'id-doc MANUAL_REVIEW on $tier',
        );
        expect(
          KycFlowManager.classify(
              tier,
              user(
                kycStatus: KycStatus.inProgress,
                idDocumentStatus: IdDocumentStatus.rejected,
              )),
          KycRoutingDecision.holdForUiApproval,
          reason: 'id-doc REJECTED on $tier',
        );
      }
    });

    test('REJECTED address holds (distinct from NOT_STARTED)', () {
      expect(
        KycFlowManager.classify(
            TierLevel.mega,
            user(
              kycStatus: KycStatus.inProgress,
              addressStatus: AddressVerificationStatus.rejected,
            )),
        KycRoutingDecision.holdForUiApproval,
      );
    });

    test('a verified sub-status under a manual-review top-level status holds '
        '(PRD wins over top-level VERIFIED)', () {
      expect(
        KycFlowManager.classify(
            TierLevel.mega,
            user(
              kycStatus: KycStatus.verified,
              idDocumentStatus: IdDocumentStatus.manualReview,
            )),
        KycRoutingDecision.holdForUiApproval,
      );
    });
  });

  group('KycFlowManager.holdState / holdReason (Slice 6)', () {
    test('holdState maps the specific async state', () {
      expect(KycFlowManager.holdState(user(kycStatus: KycStatus.manualReview)),
          KycHoldState.manualReview);
      expect(KycFlowManager.holdState(user(kycStatus: KycStatus.rejected)),
          KycHoldState.rejected);
      expect(KycFlowManager.holdState(user(kycStatus: KycStatus.expired)),
          KycHoldState.expired);
      expect(
        KycFlowManager.holdState(user(
            kycStatus: KycStatus.inProgress,
            idDocumentStatus: IdDocumentStatus.manualReview)),
        KycHoldState.idDocumentReview,
      );
      expect(
        KycFlowManager.holdState(user(
            kycStatus: KycStatus.inProgress,
            idDocumentStatus: IdDocumentStatus.rejected)),
        KycHoldState.idDocumentRejected,
      );
      expect(
        KycFlowManager.holdState(user(
            kycStatus: KycStatus.inProgress,
            addressStatus: AddressVerificationStatus.rejected)),
        KycHoldState.addressRejected,
      );
    });

    test('holdReason surfaces the server-provided reason per state', () {
      expect(
        KycFlowManager.holdReason(
            KycHoldState.rejected,
            user(
                kycStatus: KycStatus.rejected,
                rejectionReason: 'liveness failed')),
        'liveness failed',
      );
      expect(
        KycFlowManager.holdReason(
            KycHoldState.idDocumentRejected,
            user(
                kycStatus: KycStatus.inProgress,
                idDocumentStatus: IdDocumentStatus.rejected,
                idDocumentRejectionReason: 'document mismatch')),
        'document mismatch',
      );
      expect(
        KycFlowManager.holdReason(
            KycHoldState.addressRejected,
            user(
                kycStatus: KycStatus.inProgress,
                addressStatus: AddressVerificationStatus.rejected,
                addressRejectionReason: 'bill not recent')),
        'bill not recent',
      );
    });
  });
}