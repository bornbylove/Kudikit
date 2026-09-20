// lib/presentation/kyc/kyc_next_step.dart
// Shared "what comes after this KYC step succeeds" logic, used by
// chooseID.dart, upload_ID.dart, and verify_address.dart so none of them
// has to hardcode a destination screen. Kept separate from
// kyc_flow_manager.dart (which imports the three screens below) purely to
// avoid a circular import — those screens need this function too.
//
// Mirrors KycFlowManager's own tier switch, minus the selfie/BVN-NIN checks
// (already satisfied by the time any of these three screens' success
// handlers run — KycFlowManager wouldn't have routed here otherwise).

import 'package:flutter/material.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/presentation/Identity/upload_ID.dart';
import 'package:kudipay/presentation/address/verify_address.dart';

/// The tier being worked toward — user.pendingTier (set by POST
/// /auth/select-tier) wins over the locally-cached selectedTier/fallback.
/// Single source of truth for both KycFlowManager and the KYC step screens
/// (chooseID.dart etc.), which need this to know when Pro/Mega requires
/// BOTH BVN and NIN rather than either.
TierLevel effectiveKycTier(UserModel user, TierLevel fallback) {
  final pending = user.pendingTier;
  if (pending != null && pending >= 1 && pending <= 3) {
    return TierLevel.values[pending - 1];
  }
  final selected = user.selectedTier;
  if (selected >= 1 && selected <= 3) {
    return TierLevel.values[selected - 1];
  }
  return fallback;
}

/// Returns the next incomplete step's screen for [tier], or null once every
/// requirement beyond selfie/BVN-NIN is satisfied — callers should proceed
/// to ConfirmInfoScreen in that case.
Widget? nextIncompleteKycStep(TierLevel tier, UserModel user) {
  switch (tier) {
    case TierLevel.basic:
      return null;
    case TierLevel.pro:
      if (!user.isDocumentVerified) return const UploadIdCardScreen();
      return null;
    case TierLevel.mega:
      if (!user.isDocumentVerified) return const UploadIdCardScreen();
      if (user.addressStatus != AddressVerificationStatus.verified &&
          user.addressStatus != AddressVerificationStatus.pendingAgentVisit) {
        return const AddressVerificationScreen();
      }
      return null;
  }
}
