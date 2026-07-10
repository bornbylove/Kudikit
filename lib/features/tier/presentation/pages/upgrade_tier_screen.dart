import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/tier/domain/entities/tier_model.dart';
import 'package:kudipay/features/tier/presentation/controllers/tier_provider.dart';
import 'package:kudipay/features/tier/presentation/pages/upgrade_success_screen.dart';
import 'package:kudipay/features/tier/presentation/pages/upload_document_screen.dart';

class UpgradeTierScreen extends ConsumerWidget {
  final UpgradeTier tier;
  const UpgradeTierScreen({super.key, required this.tier});

  static const Color _bg = Color(0xFFF9F9F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierState = ref.watch(tierProvider);
    final allRequirementsDone = tier.requirements.every((r) => r.isCompleted);
    final isCurrentTier = tierState.currentTier == tier.level;

    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _bg,
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
                  width: AppLayout.scaleWidth(context, 76),
                  height: AppLayout.scaleWidth(context, 76),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0), // warm amber tint
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tier.icon,
                    size: AppLayout.scaleWidth(context, 36),
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
                      fontSize: AppLayout.fontSize(context, 17),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: tier.displayName),
                      TextSpan(
                        text: ' (Tier ${tier.tierNumber})',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          fontSize: AppLayout.fontSize(context, 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // ── Requirements section ──────────────────────────────────────
              _SectionLabel(text: '${tier.name} (Tier ${tier.tierNumber})'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _OutlinedCard(
                child: Column(
                  children: [
                    for (int i = 0; i < tier.requirements.length; i++) ...[
                      _RequirementRow(requirement: tier.requirements[i]),
                      if (i < tier.requirements.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Colors.grey.shade200,
                          indent: AppLayout.scaleWidth(context, 46),
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
                          height: 1,
                          thickness: 0.6,
                          color: Colors.grey.shade200,
                          indent: AppLayout.scaleWidth(context, 46),
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
        isLoading: tierState.isLoading,
        isCurrentTier: isCurrentTier,
        onTap: () => _handleUpgrade(context, ref, allRequirementsDone),
      ),
    );
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _handleUpgrade(
    BuildContext context,
    WidgetRef ref,
    bool allRequirementsDone,
  ) {
    if (allRequirementsDone) {
      _completeUpgrade(context, ref);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UploadDocumentScreen(tier: tier)),
      );
    }
  }

  Future<void> _completeUpgrade(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(tierProvider.notifier).upgradeTier(tier.level);
    if (!context.mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UpgradeSuccessScreen(tier: tier)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(tierProvider).error ?? 'Failed to upgrade tier',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
        fontSize: AppLayout.fontSize(context, 12),
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
        letterSpacing: 0.1,
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
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
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
  const _RequirementRow({required this.requirement});
  final TierRequirement requirement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      child: Row(
        children: [
          Icon(
            requirement.icon ?? Icons.circle_outlined,
            size: AppLayout.scaleWidth(context, 18),
            color: Colors.grey.shade500,
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              requirement.title,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Show teal tick only when the step is completed
          if (requirement.isCompleted)
            Icon(
              Icons.check,
              size: AppLayout.scaleWidth(context, 16),
              color: const Color(0xFF069494),
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
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: AppLayout.scaleWidth(context, 16),
            color: const Color(0xFF069494),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black87,
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
    required this.onTap,
  });

  final bool isLoading;
  final bool isCurrentTier;
  final VoidCallback onTap;

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
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 52),
          child: ElevatedButton(
            onPressed: isLoading || isCurrentTier ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentTier
                  ? Colors.grey.shade400
                  : const Color(0xFF069494),
              disabledBackgroundColor: isCurrentTier
                  ? Colors.grey.shade400
                  : const Color(0xFF069494).withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppLayout.scaleWidth(context, 32),
                ),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  )
                : Text(
                    isCurrentTier ? 'Current Tier' : 'Continue Upgrade',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
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
