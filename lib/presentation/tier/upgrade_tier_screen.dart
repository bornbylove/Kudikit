import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/tier/tier_requirements.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';



/// SLICE 8 (MO-8.2): server-authoritative tier upgrade screen.
///
/// The screen no longer simulates an upgrade locally. Everything it shows is
/// derived from the server-reconciled UserModel KYC state:
///  - `isCurrentTier`: target already GRANTED by the server (disabled CTA).
///  - `requested`: the target is PENDING (pendingTier == target) — the upgrade
///    is in progress (the PRD's "Pending" display; internal staged statuses are
///    carried on UserModel but never surfaced); the CTA resumes the KYC funnel.
///  - otherwise: "Continue Upgrade" records the server-side intent
///    (AuthNotifier.selectTier → POST /auth/select-tier) and routes into the
///    KYC funnel to complete the target's requirements.
/// Requirements rows show REAL completion/rejection (tierRequirementState),
/// never hardcoded flags.
class UpgradeTierScreen extends ConsumerStatefulWidget {
  final UpgradeTier tier;
  const UpgradeTierScreen({super.key, required this.tier});

  static const Color _bg   = Color(0xFFF9F9F9);

  @override
  ConsumerState<UpgradeTierScreen> createState() => _UpgradeTierScreenState();
}

class _UpgradeTierScreenState extends ConsumerState<UpgradeTierScreen> {
  bool _submitting = false;

  UpgradeTier get tier => widget.tier;

  @override
  Widget build(BuildContext context) {
    final user                 = ref.watch(currentUserProvider);
    final isCurrentTier        = user?.grantedTierOrZero == tier.tierNumber;
    final requested            = user?.pendingTier == tier.tierNumber;

    return Scaffold(
      backgroundColor: UpgradeTierScreen._bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: UpgradeTierScreen._bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Tier',
          style: TextStyle(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 17),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // ── Icon badge ───────────────────────────────────────────────
              Center(
                child: Container(
                  width:  AppLayout.scaleWidth(context, 76),
                  height: AppLayout.scaleWidth(context, 76),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0), // warm amber tint
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tier.icon,
                    size:  AppLayout.scaleWidth(context, 36),
                    color: const Color(0xFFFFA726), // orange-400
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // ── Title ────────────────────────────────────────────────────
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize:   AppLayout.fontSize(context, 17),
                      fontWeight: FontWeight.w700,
                      color:      Colors.black,
                      height:     1.3,
                    ),
                    children: [
                      TextSpan(text: tier.displayName),
                      TextSpan(
                        text: ' (Tier ${tier.tierNumber})',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color:      Colors.black87,
                          fontSize:   AppLayout.fontSize(context, 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // ── Server-authoritative status line ─────────────────────────
              // Honest server state: a pending upgrade is never presented as
              // granted, and a granted target shows as the current tier.
              if (requested && !isCurrentTier)
                _StatusBanner(
                  icon: Icons.hourglass_top,
                  text: 'Upgrade request pending — '
                      'complete your verification to finish.',
                ),
              if (isCurrentTier)
                _StatusBanner(
                  icon: Icons.check_circle,
                  text: 'You are already on ${tier.name} (Tier ${tier.tierNumber}).',
                ),
              if (requested && !isCurrentTier)
                SizedBox(height: AppLayout.scaleHeight(context, 12)),

              SizedBox(height: AppLayout.scaleHeight(context, 12)),

              // ── Requirements section ──────────────────────────────────────
              _SectionLabel(text: '${tier.name} (Tier ${tier.tierNumber})'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _OutlinedCard(
                child: Column(
                  children: [
                    for (int i = 0; i < tier.requirements.length; i++) ...[
                      _RequirementRow(
                        requirement: tier.requirements[i],
                        state: user == null
                            ? TierRequirementState.incomplete
                            : tierRequirementState(
                                tier.requirements[i].title, user),
                      ),
                      if (i < tier.requirements.length - 1)
                        Divider(
                          height:    1,
                          thickness: 0.6,
                          color:     Colors.grey.shade200,
                          indent:    AppLayout.scaleWidth(context, 46),
                        ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // ── Benefits section ──────────────────────────────────────────
              _SectionLabel(text: '${tier.name} Benefits'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _OutlinedCard(
                child: Column(
                  children: [
                    for (int i = 0; i < tier.benefits.length; i++) ...[
                      _BenefitRow(benefit: tier.benefits[i]),
                      if (i < tier.benefits.length - 1)
                        Divider(
                          height:    1,
                          thickness: 0.6,
                          color:     Colors.grey.shade200,
                          indent:    AppLayout.scaleWidth(context, 46),
                        ),
                    ],
                  ],
                ),
              ),

              // Bottom breathing room above the fixed button
              SizedBox(height: AppLayout.scaleHeight(context, 120)),
            ],
          ),
        ),
      ),

      // ── Bottom CTA ────────────────────────────────────────────────────────
      bottomNavigationBar: _BottomButton(
        isLoading:     _submitting,
        isCurrentTier: isCurrentTier,
        label: isCurrentTier
            ? 'Current Tier'
            : (requested ? 'Continue Verification' : 'Continue Upgrade'),
        onTap: () => _handleUpgrade(context),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _handleUpgrade(BuildContext context) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (user.grantedTierOrZero == tier.tierNumber) return;

    // Intent already recorded server-side → resume the PRD KYC funnel.
    if (user.pendingTier == tier.tierNumber) {
      _goToKyc(context);
      return;
    }
    _submitUpgrade(context);
  }

  /// Records the upgrade request server-side (POST /auth/select-tier sets
  /// pendingTier and auto-grants when KYC requirements are already met), then
  /// routes into the KYC funnel to complete the target's remaining
  /// requirements. The server result is authoritative — no local simulation.
  Future<void> _submitUpgrade(BuildContext context) async {
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).selectTier(tier.tierNumber);
      if (!context.mounted) return;
      _goToKyc(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToKyc(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycFlowManager()),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// Grey section label rendered above each card.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize:   AppLayout.fontSize(context, 12),
        fontWeight: FontWeight.w500,
        color:      Colors.grey.shade600,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// Inline server-state banner (pending upgrade / already current).
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 12),
        vertical: AppLayout.scaleHeight(context, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF069494).withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: AppLayout.scaleWidth(context, 16),
              color: const Color(0xFF069494)),
          SizedBox(width: AppLayout.scaleWidth(context, 8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 2),
        ),
        child: child,
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement, required this.state});
  final TierRequirement requirement;
  final TierRequirementState state;

  @override
  Widget build(BuildContext context) {
    final bool completed = state == TierRequirementState.completed;
    final bool rejected  = state == TierRequirementState.rejected;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical:   AppLayout.scaleHeight(context, 14),
      ),
      child: Row(
        children: [
          Icon(
            requirement.icon ?? Icons.circle_outlined,
            size:  AppLayout.scaleWidth(context, 18),
            color: rejected
                ? Colors.red.shade400
                : (completed
                    ? const Color(0xFF069494)
                    : Colors.grey.shade500),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              requirement.title,
              style: TextStyle(
                fontSize:   AppLayout.fontSize(context, 14),
                color:      rejected ? Colors.red.shade700 : Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (completed)
            Icon(
              Icons.check,
              size:  AppLayout.scaleWidth(context, 16),
              color: const Color(0xFF069494),
            )
          else if (rejected)
            Icon(
              Icons.close,
              size:  AppLayout.scaleWidth(context, 16),
              color: Colors.red.shade400,
            ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});
  final TierBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final text = benefit.value != null
        ? '${benefit.title}: ${benefit.value}'
        : benefit.title;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical:   AppLayout.scaleHeight(context, 14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size:  AppLayout.scaleWidth(context, 16),
            color: const Color(0xFF069494),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize:   AppLayout.fontSize(context, 14),
                color:      Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.isLoading,
    required this.isCurrentTier,
    required this.label,
    required this.onTap,
  });

  final bool          isLoading;
  final bool          isCurrentTier;
  final String        label;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 10),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
        ),
        child: SizedBox(
          width:  double.infinity,
          height: AppLayout.scaleHeight(context, 52),
          child: ElevatedButton(
            onPressed: isLoading || isCurrentTier ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentTier
                  ? Colors.grey.shade400
                  : const Color(0xFF069494),
              disabledBackgroundColor: isCurrentTier
                  ? Colors.grey.shade400
                  : const Color(0xFF069494).withOpacity(0.55),
              foregroundColor:         Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation:    0,
              shadowColor:  Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppLayout.scaleWidth(context, 32),
                ),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width:  22,
                    height: 22,
                    child:  CircularProgressIndicator(
                      color:       Colors.white,
                      strokeWidth: 1.5,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize:   AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
