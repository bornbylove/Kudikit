import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:kudipay/formatting/widget/bottom_nav.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
import 'package:kudipay/presentation/Identity/upload_ID.dart';
import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';

// =============================================================================
// KycFlowManager
// -----------------------------------------------------------------------------
// Smart router that drops the user into the correct NEXT incomplete KYC step
// based on their selected tier AND the KYC flags already set on their
// UserModel. Returning users are never sent back to a completed step.
//
// SLICE 6 — PRD-ALIGNED ROUTING TABLE (tier-aware, server-authoritative):
// ─────────────────────────────────────────────────────────────────────────────
// Tier 1 (Basic)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN OR NIN verification    [isBvnVerified || isNinVerified]
//   → Confirm Info → PIN → Account Ready → Dashboard
//
// Tier 2 (Pro)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN AND NIN verification   [isBvnVerified && isNinVerified]
//   3. ID document upload         [idDocumentStatus == VERIFIED]
//   → Confirm Info → PIN → Account Ready → Dashboard
//
// Tier 3 (Mega)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN AND NIN verification   [isBvnVerified && isNinVerified]
//   3. ID document upload         [idDocumentStatus == VERIFIED]
//   4. Address + utility bill     [addressStatus == VERIFIED | PENDING_AGENT_VISIT]
//   → Confirm Info → PIN → Account Ready → Dashboard
//
// KEY SLICE 6 CHANGES:
//  * Completion is PER-TIER, not top-level KycStatus: the auth-service flips
//    top-level status to VERIFIED as soon as BVN OR NIN succeeds, which is NOT
//    equivalent to Pro/Mega completion. A Pro/Mega user must not reach the
//    dashboard until BVN AND NIN AND ID (AND address for Mega) are satisfied.
//  * PENDING_AGENT_VISIT on a Mega target is the PRD's INTERIM TIER: Pro is
//    complete and address is in flight → the user goes to the dashboard (on
//    Tier-2 limits) instead of a dead loading screen.
//  * MANUAL_REVIEW / REJECTED / EXPIRED are no longer a generic loading hold —
//    they route to a minimal status surface (see _KycStatusScreen) with the
//    server's reason and a refresh/retry action.
//  * The routing tier is SERVER-AUTHORITATIVE: user.pendingTier (set by
//    POST /auth/select-tier) wins; local tierProvider is only a fallback.
// =============================================================================

/// Authoritative, UI-independent classification of where the user belongs.
/// Public + static so the routing decisions are unit-testable without
/// pumping widget trees.
enum KycRoutingDecision {
  /// All PRD requirements for the target tier are met (or the PRD's interim
  /// tier applies) — user belongs at the main app shell.
  complete,

  /// Server KYC state says the frozen funnel applies — resume via the boolean
  /// funnel at the first incomplete step.
  continueFunnel,

  /// A server state with no representation in the frozen funnel (REJECTED /
  /// MANUAL_REVIEW / EXPIRED / REJECTED id-doc / REJECTED address) — route to
  /// the minimal status surface with reason + refresh/retry.
  holdForUiApproval,
}

/// Specific async server state for [KycRoutingDecision.holdForUiApproval].
enum KycHoldState {
  manualReview,
  rejected,
  expired,
  idDocumentReview,
  idDocumentRejected,
  addressRejected;

  /// Top-level REJECTED id-doc/address carry their own state; this is the
  /// fallback for any rejected signal.
  bool get isRejected =>
      this == rejected || this == idDocumentRejected || this == addressRejected;
}

class KycFlowManager extends ConsumerWidget {
  const KycFlowManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user              = ref.watch(currentUserProvider);
    final tierState         = ref.watch(tierProvider);
    final connectivityState = ref.watch(connectivityStateProvider);

    // ── Offline guard ────────────────────────────────────────────────────────
    if (!connectivityState.isConnected) {
      return _OfflineScreen(
        onRetry: () =>
            ref.read(connectivityStateProvider.notifier).refresh(),
        onBack: () => Navigator.pop(context),
      );
    }

    // ── Loading guard ────────────────────────────────────────────────────────
    if (user == null || tierState.isLoading) {
      return const _LoadingScreen(message: 'Loading your information...');
    }

    // ── Resolve the next step from the server-authoritative state ────────────
    // SLICE 6: the routing tier is server-authoritative (user.pendingTier),
    // falling back to the local tier provider for legacy/cached users.
    final tier     = KycFlowManager.effectiveTier(user, tierState.currentTier);
    final decision = KycFlowManager.classify(tier, user);
    final nextScreen = _resolveNextScreen(tier, user, decision);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    });

    // Transitional placeholder shown for one frame while navigation is queued
    return _LoadingScreen(message: _loadingMessage(tier, user, decision));
  }

  // ---------------------------------------------------------------------------
  // EFFECTIVE TIER (Slice 6 — server-authoritative)
  // pendingTier (set by POST /auth/select-tier) is the tier being worked
  // toward; it wins over the local tierProvider / selectedTier cache.
  // ---------------------------------------------------------------------------
  static TierLevel effectiveTier(UserModel user, TierLevel fallback) {
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

  // ---------------------------------------------------------------------------
  // PRD-AUTHORITATIVE CLASSIFIER (Slice 6)
  // Completion is evaluated against the TARGET tier's PRD requirements, not the
  // server's top-level KycStatus (which flips to VERIFIED after just BVN or NIN).
  // ---------------------------------------------------------------------------
  static KycRoutingDecision classify(TierLevel tier, UserModel user) {
    // 1. Async hold states that block the funnel and need explicit surfacing.
    if (user.kycStatus == KycStatus.manualReview ||
        user.kycStatus == KycStatus.rejected ||
        user.kycStatus == KycStatus.expired) {
      return KycRoutingDecision.holdForUiApproval;
    }
    if (user.idDocumentStatus == IdDocumentStatus.manualReview ||
        user.idDocumentStatus == IdDocumentStatus.rejected) {
      return KycRoutingDecision.holdForUiApproval;
    }
    if (user.addressStatus == AddressVerificationStatus.rejected) {
      return KycRoutingDecision.holdForUiApproval;
    }

    // 2. Tier-aware completion. For Mega, PENDING_AGENT_VISIT is the PRD's
    //    interim tier — Pro is complete and address is in flight, so the user
    //    belongs on the dashboard (Tier-2 limits) rather than a hold.
    final complete = switch (tier) {
      TierLevel.basic =>
        user.isSelfieVerified && (user.isBvnVerified || user.isNinVerified),
      TierLevel.pro =>
        user.isSelfieVerified &&
        user.isBvnVerified &&
        user.isNinVerified &&
        user.idDocumentStatus == IdDocumentStatus.verified,
      TierLevel.mega =>
        user.isSelfieVerified &&
        user.isBvnVerified &&
        user.isNinVerified &&
        user.idDocumentStatus == IdDocumentStatus.verified &&
        (user.addressStatus == AddressVerificationStatus.verified ||
            user.addressStatus == AddressVerificationStatus.pendingAgentVisit),
    };
    if (complete) {
      return KycRoutingDecision.complete;
    }

    // 3. A PENDING row with NO verification activity is the getOrCreate()
    //    artifact — genuinely startable, treated like NOT_STARTED.
    if (user.kycStatus == KycStatus.pending && !_hasKycActivity(user)) {
      return KycRoutingDecision.continueFunnel;
    }

    // 4. Everything else resumes/continues the funnel at the first incomplete
    //    step (NOT_STARTED / IN_PROGRESS / in-flight PENDING with unmet steps).
    return KycRoutingDecision.continueFunnel;
  }

  static bool _hasKycActivity(UserModel user) {
    return user.isBvnVerified ||
        user.isNinVerified ||
        user.isSelfieVerified ||
        user.isDocumentVerified ||
        user.isAddressVerified ||
        user.idDocumentStatus != IdDocumentStatus.notStarted ||
        user.addressStatus != AddressVerificationStatus.notStarted ||
        user.requiresManualReview;
  }

  /// The specific async state to surface for [KycRoutingDecision.holdForUiApproval].
  static KycHoldState holdState(UserModel user) {
    if (user.kycStatus == KycStatus.manualReview) return KycHoldState.manualReview;
    if (user.kycStatus == KycStatus.expired) return KycHoldState.expired;
    if (user.kycStatus == KycStatus.rejected) return KycHoldState.rejected;
    if (user.idDocumentStatus == IdDocumentStatus.manualReview) {
      return KycHoldState.idDocumentReview;
    }
    if (user.idDocumentStatus == IdDocumentStatus.rejected) {
      return KycHoldState.idDocumentRejected;
    }
    if (user.addressStatus == AddressVerificationStatus.rejected) {
      return KycHoldState.addressRejected;
    }
    return KycHoldState.manualReview;
  }

  /// The server-provided reason for the current hold state (when available).
  static String? holdReason(KycHoldState state, UserModel user) {
    switch (state) {
      case KycHoldState.rejected:
      case KycHoldState.expired:
        return user.rejectionReason;
      case KycHoldState.idDocumentReview:
      case KycHoldState.idDocumentRejected:
        return user.idDocumentRejectionReason;
      case KycHoldState.addressRejected:
        return user.addressRejectionReason;
      case KycHoldState.manualReview:
        return user.rejectionReason;
    }
  }

  // ---------------------------------------------------------------------------
  // ROUTING LOGIC
  // Walk each tier's funnel top-to-bottom. Return the first screen whose
  // prerequisite is NOT yet satisfied. Only reached for continueFunnel /
  // complete (authoritative gate above).
  // ---------------------------------------------------------------------------
  Widget _resolveNextScreen(TierLevel tier, UserModel user,
      KycRoutingDecision decision) {
    switch (decision) {
      case KycRoutingDecision.complete:
        return const BottomNavBar();
      case KycRoutingDecision.holdForUiApproval:
        return _KycStatusScreen(
          state: holdState(user),
          reason: holdReason(holdState(user), user),
        );
      case KycRoutingDecision.continueFunnel:
        break;
    }
    switch (tier) {

      // ── Tier 1 (Basic): Selfie → (BVN OR NIN) ─────────────────────────────
      case TierLevel.basic:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified && !user.isNinVerified) {
          return const IdVerificationScreen();
        }
        return const BottomNavBar();

      // ── Tier 2 (Pro): Selfie → BVN AND NIN → ID document ──────────────────
      case TierLevel.pro:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified || !user.isNinVerified) {
          return const IdVerificationScreen();
        }
        if (!user.isDocumentVerified) return const UploadIdCardScreen();
        return const BottomNavBar();

      // ── Tier 3 (Mega): Selfie → BVN AND NIN → ID → Address ────────────────
      case TierLevel.mega:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified || !user.isNinVerified) {
          return const IdVerificationScreen();
        }
        if (!user.isDocumentVerified) return const UploadIdCardScreen();
        if (user.addressStatus != AddressVerificationStatus.verified &&
            user.addressStatus != AddressVerificationStatus.pendingAgentVisit) {
          return const AddressVerificationScreen();
        }
        return const BottomNavBar();
    }
  }

  // ---------------------------------------------------------------------------
  // Human-readable loading message shown during the one-frame transition
  // ---------------------------------------------------------------------------
  String _loadingMessage(
      TierLevel tier, UserModel user, KycRoutingDecision decision) {
    if (decision == KycRoutingDecision.holdForUiApproval) {
      return 'Loading your information...';
    }
    switch (tier) {
      case TierLevel.basic:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified && !user.isNinVerified) {
          return 'Preparing identity verification...';
        }
        return 'Preparing your dashboard...';

      case TierLevel.pro:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified || !user.isNinVerified) {
          return 'Preparing identity verification...';
        }
        if (!user.isDocumentVerified) return 'Preparing document upload...';
        return 'Preparing your dashboard...';

      case TierLevel.mega:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified || !user.isNinVerified) {
          return 'Preparing identity verification...';
        }
        if (!user.isDocumentVerified) return 'Preparing document upload...';
        if (user.addressStatus != AddressVerificationStatus.verified &&
            user.addressStatus != AddressVerificationStatus.pendingAgentVisit) {
          return 'Preparing address verification...';
        }
        return 'Preparing your dashboard...';
    }
  }
}

// =============================================================================
// _KycStatusScreen — minimal status surface for PENDING_AGENT_VISIT /
// MANUAL_REVIEW / REJECTED / EXPIRED (Slice 6, MO-3). Replaces the dead
// loading hold. NOT a redesign: reuses the app's existing palette/typography,
// shows the server's state + reason, and offers Refresh Status / Try Again.
// =============================================================================
class _KycStatusScreen extends ConsumerStatefulWidget {
  final KycHoldState state;
  final String? reason;

  const _KycStatusScreen({required this.state, this.reason});

  @override
  ConsumerState<_KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends ConsumerState<_KycStatusScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(authProvider.notifier).refreshKycStatus();
    if (!mounted) return;
    setState(() => _refreshing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycFlowManager()),
    );
  }

  void _retry() {
    // Re-route into the funnel so the user can resubmit the failed step.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycFlowManager()),
    );
  }

  ({IconData icon, Color color, String title, String message}) get _content {
    switch (widget.state) {
      case KycHoldState.addressRejected:
        return (
          icon: Icons.location_off,
          color: const Color(0xFFD32F2F),
          title: 'Address verification failed',
          message:
              'We could not verify your address. Please review your details and '
              'utility bill, then try again.',
        );
      case KycHoldState.idDocumentReview:
      case KycHoldState.manualReview:
        return (
          icon: Icons.verified_user,
          color: const Color(0xFFF57C00),
          title: 'Verification under review',
          message:
              'Your details have been submitted for manual review. This usually '
              'takes a short time. We will update you once the review is complete.',
        );
      case KycHoldState.idDocumentRejected:
        return (
          icon: Icons.badge_outlined,
          color: const Color(0xFFD32F2F),
          title: 'ID document rejected',
          message:
              'We could not validate your ID document. Please check the document '
              'is clear and not expired, then upload it again.',
        );
      case KycHoldState.rejected:
        return (
          icon: Icons.error_outline,
          color: const Color(0xFFD32F2F),
          title: 'Verification failed',
          message:
              'We could not verify your identity. Please review your details and '
              'try again.',
        );
      case KycHoldState.expired:
        return (
          icon: Icons.hourglass_empty,
          color: const Color(0xFFF57C00),
          title: 'Verification expired',
          message:
              'Your verification session expired. Please start your identity '
              'verification again.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    final canRetry = widget.state.isRejected;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 88),
                height: AppLayout.scaleWidth(context, 88),
                decoration: BoxDecoration(
                  color: content.color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  content.icon,
                  size: AppLayout.scaleWidth(context, 42),
                  color: content.color,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 10)),
              Text(
                content.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              if (widget.reason != null && widget.reason!.trim().isNotEmpty) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 16)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
                  decoration: BoxDecoration(
                    color: content.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 8)),
                    border: Border.all(
                        color: content.color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    widget.reason!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
              SizedBox(height: AppLayout.scaleHeight(context, 28)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  icon: _refreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Refresh Status',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              if (canRetry) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                SizedBox(
                  width: double.infinity,
                  height: AppLayout.scaleHeight(context, 52),
                  child: OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 28)),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _LoadingScreen — shown for one frame while navigation is pending, and also
// during the initial data fetch (user == null || tierState.isLoading).
// =============================================================================
class _LoadingScreen extends StatelessWidget {
  final String message;
  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                color: AppColors.textGrey,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
            // Subtle online indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppLayout.scaleWidth(context, 8),
                  height: AppLayout.scaleWidth(context, 8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _OfflineScreen — shown when there is no internet connection.
// Extracted to a separate widget to keep KycFlowManager's build() readable.
// =============================================================================
class _OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _OfflineScreen({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon ────────────────────────────────────────────────────
              Container(
                width: AppLayout.scaleWidth(context, 120),
                height: AppLayout.scaleWidth(context, 120),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: AppLayout.scaleWidth(context, 60),
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // ── Title ────────────────────────────────────────────────────
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 22),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                'KYC verification requires an active internet connection. '
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // ── Check Connection button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 54),
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Check Connection',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),

              // ── Go Back ──────────────────────────────────────────────────
              TextButton(
                onPressed: onBack,
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // ── Tips card ────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 12)),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: AppLayout.scaleWidth(context, 18),
                            color: Colors.blue.shade700),
                        SizedBox(width: AppLayout.scaleWidth(context, 8)),
                        Text(
                          'Connection Tips',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 13),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 12)),
                    ...[
                      'Turn on WiFi or mobile data',
                      'Check airplane mode is off',
                      'Try moving to a different location',
                      'Restart your device if needed',
                    ].map((tip) => _Tip(tip: tip)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String tip;
  const _Tip({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}