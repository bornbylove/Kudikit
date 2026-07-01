import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudipay/presentation/agent/agent_registration_flow.dart';
import 'package:kudipay/presentation/agent/agent_registration_widgets.dart';

// -- Screen: Tier 2 Required Gate ----------------------------------------------

class TierCheckScreen extends ConsumerWidget {
  const TierCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierState = ref.watch(tierProvider);
    final isTier2OrAbove = tierState.currentTier == TierLevel.pro ||
        tierState.currentTier == TierLevel.mega;

    // If the user already holds Tier 2+, skip the gate entirely and
    // show the verified confirmation screen directly.
    if (isTier2OrAbove) {
      return const IdentityVerifiedScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: KudiCircularProgress(progress: 0.36),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // -- Lock icon ------------------------------------------------
              Container(
                width: AppLayout.scaleWidth(context, 72),
                height: AppLayout.scaleWidth(context, 72),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryTeal,
                  size: AppLayout.scaleWidth(context, 34),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              Text(
                'Tier 2 Verification Required',
                style: TextStyle(
                  fontFamily: 'PolySans',
                  fontSize: AppLayout.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                'You need to complete Tier 2 identity verification before applying to become a KudiKit agent.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate into the real KYC flow manager.
                    // KycFlowManager reads tierProvider and routes the user
                    // through Selfie ? ID ? Address for Tier 2, then
                    // returns them here once complete (tier state updated).
                    Navigator.push(
                      context,
                      PageTransition(const KycFlowManager()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: Text(
                    'Start Identity Verification',
                    style: AppTextStyles.responsiveButtonText(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Screen: Identity Verified -------------------------------------------------

class IdentityVerifiedScreen extends ConsumerWidget {
  const IdentityVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read real user data from providers instead of hardcoded strings.
    final tierState = ref.watch(tierProvider);
    final currentTierLabel = tierState.currentTier == TierLevel.mega
        ? "Tier 3 (Mega)"
        : tierState.currentTier == TierLevel.pro
            ? "Tier 2 (Pro)"
            : "Tier 1 (Basic)";

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: KudiCircularProgress(progress: 1.0),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // -- Success banner ---------------------------------------------
            KudiCard(
              child: Row(
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 44),
                    height: AppLayout.scaleWidth(context, 44),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: AppLayout.scaleWidth(context, 22),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity Verified!',
                          style: TextStyle(
                            fontFamily: 'PolySans',
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 2)),
                        Text(
                          'Your $currentTierLabel KYC verification is complete',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // -- What's next card -------------------------------------------
            KudiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re ready to apply',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  Text(
                    'Your identity has been verified. Tap Continue below to complete your agent application.',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  const _BvnStatusRow(),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 100)),
          ],
        ),
      ),
      bottomNavigationBar: KudiPrimaryButton(
        label: 'Continue to Agent Application',
        onPressed: () => Navigator.pushReplacement(
          context,
          PageTransition(const AgentRegistrationFlow()),
        ),
      ),
    );
  }
}

// -- Private sub-widgets (local to this file only) -----------------------------

class _BvnStatusRow extends StatelessWidget {
  const _BvnStatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.primaryTeal,
          size: AppLayout.scaleWidth(context, 16),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 6)),
        Text(
          'BVN Verified',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
