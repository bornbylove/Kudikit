// lib/model/tier/tier_requirements.dart
// ─────────────────────────────────────────────────────────────────────────────
// SLICE 8 (MO-8.4): PRD-authoritative tier-upgrade semantics, pure and
// testable. These helpers reconcile the display/decision logic of the upgrade
// flow against the SERVER-AUTHORITATIVE KYC state on the UserModel (the
// auth-service owns KYC truth). They exist so the mobile tier-upgrade UI can
// show real completion/rejection per PRD requirement, enforce the no-skip rule
// (Tier 1 -> 2 -> 3, PRD §2.2.4) at the navigation boundary, and NEVER fabricate
// an upgrade the server has not granted.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';

/// Display state of a single PRD upgrade requirement, derived from server KYC
/// truth. `rejected` is surfaced ONLY where the server provides a rejection for
/// the underlying KYC field (idDocumentStatus / addressStatus / top-level
/// KycStatus) — the app never infers rejection on its own.
enum TierRequirementState {
  incomplete,
  completed,
  rejected,
}

/// The single next tier above the server-granted [grantedTier] — the only tier
/// the upgrade flow may offer (no-skip: 1 -> 2 -> 3, PRD §2.2.4). Returns null
/// when there is no next tier: already at Mega (3), or UNVERIFIED (0) where the
/// concept of "upgrade" does not apply (those users enter the KYC funnel
/// directly).
UpgradeTier? nextUpgradeTier(int grantedTier) {
  switch (grantedTier) {
    case 1:
      return UpgradeTier.proTier();
    case 2:
      return UpgradeTier.megaTier();
    default:
      return null; // 3 (max) or 0 (UNVERIFIED)
  }
}

/// Maps a PRD requirement [title] (matching the `TierRequirement.title` values
/// in tier_model.dart) to its display state from [user]'s server KYC state.
///
/// PRD tier model: Basic = Selfie + (BVN OR NIN); Pro = + BVN AND NIN + valid
/// ID (front & back); Mega = + verified address (+ utility bill, analyzed with
/// the address submission). The utility bill has no dedicated server field — its
/// completion tracks the address-verification step that carries it.
TierRequirementState tierRequirementState(String title, UserModel user) {
  switch (title) {
    case 'Email Verification':
      return user.isEmailVerified
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'Phone Verification':
      return user.isPhoneVerified
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'NIN / BVN':
      // Pro/Mega require BVN AND NIN. A top-level REJECTED surfaces the
      // rejection; otherwise both must be server-verified.
      if (user.kycStatus == KycStatus.rejected) {
        return TierRequirementState.rejected;
      }
      return (user.isBvnVerified && user.isNinVerified)
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'Face verification':
      if (user.kycStatus == KycStatus.rejected) {
        return TierRequirementState.rejected;
      }
      return user.isSelfieVerified
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'Valid ID Card (Front & Back)':
      if (user.idDocumentStatus == IdDocumentStatus.rejected) {
        return TierRequirementState.rejected;
      }
      return user.idDocumentStatus == IdDocumentStatus.verified
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'Address Verification (Agent visit)':
      if (user.addressStatus == AddressVerificationStatus.rejected) {
        return TierRequirementState.rejected;
      }
      // PENDING_AGENT_VISIT is the PRD interim tier: the address (with the
      // utility bill) has been submitted and an agent visit is scheduled —
      // the address requirement counts as done for the interim tier.
      return (user.addressStatus == AddressVerificationStatus.verified ||
              user.addressStatus == AddressVerificationStatus.pendingAgentVisit)
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    case 'Utility Bill':
      if (user.addressStatus == AddressVerificationStatus.rejected) {
        return TierRequirementState.rejected;
      }
      return (user.addressStatus == AddressVerificationStatus.verified ||
              user.addressStatus == AddressVerificationStatus.pendingAgentVisit)
          ? TierRequirementState.completed
          : TierRequirementState.incomplete;

    default:
      return TierRequirementState.incomplete;
  }
}

/// Whether every PRD requirement of [tier] is satisfied by [user] (per the
/// server-reconciled KYC state). Used to decide the upgrade CTA and to avoid
/// re-submitting KYC already completed.
bool upgradeTierRequirementsComplete(UpgradeTier tier, UserModel user) {
  if (tier.requirements.isEmpty) return true;
  return tier.requirements.every((r) =>
      tierRequirementState(r.title, user) == TierRequirementState.completed);
}
