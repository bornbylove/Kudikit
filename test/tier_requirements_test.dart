// test/tier_requirements_test.dart
//
// SLICE 8 (MO-8.5): PRD-authoritative tier-upgrade semantics. Pure unit tests
// on the tier_requirements helpers — no widget pumping (matches the repo's
// classifier-test convention):
//  - nextUpgradeTier: no-skip derivation (Tier 1 -> 2 -> 3, PRD §2.2.4); the
//    upgrade flow may only ever offer granted+1.
//  - tierRequirementState: PRD requirement -> real server-reconciled KYC state,
//    including REJECTED surfacing only where the server provides it.
//  - upgradeTierRequirementsComplete: whole-tier completion gate.
// These mirror the server-authoritative rule that a pending or locally-selected
// tier must NEVER be displayed as granted.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/tier/tier_requirements.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';

void main() {
  UserModel user({
    KycStatus kycStatus = KycStatus.notStarted,
    IdDocumentStatus idDocumentStatus = IdDocumentStatus.notStarted,
    AddressVerificationStatus addressStatus =
        AddressVerificationStatus.notStarted,
    bool isSelfieVerified = false,
    bool isBvnVerified = false,
    bool isNinVerified = false,
    bool isEmailVerified = true,
    bool isPhoneVerified = true,
    int? pendingTier,
    int? grantedTier,
  }) {
    return UserModel(
      userId: 'c-1',
      email: 'a@b.com',
      phoneNumber: '+2348012345678',
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      kycStatus: kycStatus,
      idDocumentStatus: idDocumentStatus,
      addressStatus: addressStatus,
      isSelfieVerified: isSelfieVerified,
      isBvnVerified: isBvnVerified,
      isNinVerified: isNinVerified,
      pendingTier: pendingTier,
      grantedTier: grantedTier,
    );
  }

  group('nextUpgradeTier (no-skip, PRD §2.2.4)', () {
    test('Basic (1) upgrades to Pro (2) — never straight to Mega', () {
      final target = nextUpgradeTier(1);
      expect(target, isNotNull);
      expect(target!.tierNumber, 2);
    });

    test('Pro (2) upgrades to Mega (3)', () {
      final target = nextUpgradeTier(2);
      expect(target, isNotNull);
      expect(target!.tierNumber, 3);
    });

    test('Mega (3) has no further tier — upgrade entry is hidden', () {
      expect(nextUpgradeTier(3), isNull);
    });

    test('UNVERIFIED (0) has no upgrade — those users enter KYC directly', () {
      expect(nextUpgradeTier(0), isNull);
    });
  });

  group('tierRequirementState — PRD requirement to server KYC truth', () {
    test('NIN / BVN is completed only when BOTH are server-verified (Pro/Mega '
        'require BVN AND NIN)', () {
      final u = user(isBvnVerified: true, isNinVerified: true);
      expect(tierRequirementState('NIN / BVN', u),
          TierRequirementState.completed);
      expect(tierRequirementState('NIN / BVN', user(isBvnVerified: true)),
          TierRequirementState.incomplete,
          reason: 'BVN only — NIN missing');
      expect(tierRequirementState('NIN / BVN', user(isNinVerified: true)),
          TierRequirementState.incomplete,
          reason: 'NIN only — BVN missing');
    });

    test('NIN / BVN is rejected only when the server REJECTED KYC', () {
      expect(
          tierRequirementState(
              'NIN / BVN', user(kycStatus: KycStatus.rejected)),
          TierRequirementState.rejected);
    });

    test('Face verification follows the server liveness flag', () {
      expect(tierRequirementState('Face verification', user(isSelfieVerified: true)),
          TierRequirementState.completed);
      expect(tierRequirementState('Face verification', user()),
          TierRequirementState.incomplete);
      expect(
          tierRequirementState(
              'Face verification', user(kycStatus: KycStatus.rejected)),
          TierRequirementState.rejected);
    });

    test('Valid ID Card (Front & Back) follows idDocumentStatus', () {
      expect(
          tierRequirementState('Valid ID Card (Front & Back)',
              user(idDocumentStatus: IdDocumentStatus.verified)),
          TierRequirementState.completed);
      expect(
          tierRequirementState('Valid ID Card (Front & Back)',
              user(idDocumentStatus: IdDocumentStatus.manualReview)),
          TierRequirementState.incomplete);
      expect(
          tierRequirementState('Valid ID Card (Front & Back)',
              user(idDocumentStatus: IdDocumentStatus.rejected)),
          TierRequirementState.rejected,
          reason: 'server idDocument REJECTED surfaces as rejected');
    });

    test('Address Verification (Agent visit) completes when verified or '
        'pending-agent-visit (PRD interim tier)', () {
      expect(
          tierRequirementState('Address Verification (Agent visit)',
              user(addressStatus: AddressVerificationStatus.verified)),
          TierRequirementState.completed);
      expect(
          tierRequirementState('Address Verification (Agent visit)',
              user(addressStatus: AddressVerificationStatus.pendingAgentVisit)),
          TierRequirementState.completed,
          reason: 'PRD interim tier — address submitted, agent visit pending');
      expect(
          tierRequirementState('Address Verification (Agent visit)',
              user(addressStatus: AddressVerificationStatus.notStarted)),
          TierRequirementState.incomplete);
      expect(
          tierRequirementState('Address Verification (Agent visit)',
              user(addressStatus: AddressVerificationStatus.rejected)),
          TierRequirementState.rejected);
    });

    test('Utility Bill tracks the address-verification step that carries it', () {
      expect(
          tierRequirementState('Utility Bill',
              user(addressStatus: AddressVerificationStatus.verified)),
          TierRequirementState.completed);
      expect(
          tierRequirementState('Utility Bill',
              user(addressStatus: AddressVerificationStatus.pendingAgentVisit)),
          TierRequirementState.completed);
      expect(
          tierRequirementState('Utility Bill',
              user(addressStatus: AddressVerificationStatus.rejected)),
          TierRequirementState.rejected);
    });

    test('Email/Phone verification map to the verified flags', () {
      expect(tierRequirementState('Email Verification', user()),
          TierRequirementState.completed);
      expect(
          tierRequirementState(
              'Email Verification', user(isEmailVerified: false)),
          TierRequirementState.incomplete);
      expect(
          tierRequirementState(
              'Phone Verification', user(isPhoneVerified: false)),
          TierRequirementState.incomplete);
    });

    test('unknown titles are incomplete (never guessed as done)', () {
      expect(tierRequirementState('Something Else', user()),
          TierRequirementState.incomplete);
    });
  });

  group('upgradeTierRequirementsComplete — whole-tier gate', () {
    test('Pro is NOT complete with BVN only (needs NIN + selfie + ID)', () {
      expect(
          upgradeTierRequirementsComplete(
              UpgradeTier.proTier(),
              user(isBvnVerified: true, isNinVerified: true,
                  isSelfieVerified: true)),
          isFalse,
          reason: 'ID card still missing');
    });

    test('Pro IS complete with BVN + NIN + selfie + verified ID', () {
      expect(
          upgradeTierRequirementsComplete(
              UpgradeTier.proTier(),
              user(
                  isBvnVerified: true,
                  isNinVerified: true,
                  isSelfieVerified: true,
                  idDocumentStatus: IdDocumentStatus.verified)),
          isTrue);
    });

    test('Mega IS complete when Pro requirements + verified address are met', () {
      expect(
          upgradeTierRequirementsComplete(
              UpgradeTier.megaTier(),
              user(
                  isBvnVerified: true,
                  isNinVerified: true,
                  isSelfieVerified: true,
                  idDocumentStatus: IdDocumentStatus.verified,
                  addressStatus: AddressVerificationStatus.pendingAgentVisit)),
          isTrue,
          reason: 'pending-agent-visit satisfies the address step (interim)');
    });

    test('Mega is NOT complete when the address step is rejected', () {
      expect(
          upgradeTierRequirementsComplete(
              UpgradeTier.megaTier(),
              user(
                  isBvnVerified: true,
                  isNinVerified: true,
                  isSelfieVerified: true,
                  idDocumentStatus: IdDocumentStatus.verified,
                  addressStatus: AddressVerificationStatus.rejected)),
          isFalse);
    });

    test('Basic is complete by default (email + phone verified)', () {
      expect(upgradeTierRequirementsComplete(UpgradeTier.basicTier(), user()),
          isTrue);
    });
  });

  group('granted vs pending semantics (never present pending as granted)', () {
    test('nextUpgradeTier uses grantedTier, not pendingTier', () {
      // pendingTier=3, granted=1 → the flow still offers Pro (2): a user can
      // never skip 1 -> 3 even if a Mega request is pending.
      expect(nextUpgradeTier(user(pendingTier: 3, grantedTier: 1).grantedTierOrZero)!
          .tierNumber, 2);
    });

    test('a granted tier is the sole driver of the upgrade entry', () {
      expect(nextUpgradeTier(user(grantedTier: 2).grantedTierOrZero)!.tierNumber,
          3);
      expect(nextUpgradeTier(user(grantedTier: 3).grantedTierOrZero), isNull);
      expect(nextUpgradeTier(user(grantedTier: null).grantedTierOrZero), isNull,
          reason: 'UNVERIFIED (no grant)');
    });
  });
}
