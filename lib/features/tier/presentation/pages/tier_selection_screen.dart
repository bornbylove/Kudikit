import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/tier/domain/entities/tier_model.dart';
import 'package:kudipay/features/tier/presentation/pages/upgrade_tier_screen.dart';
import 'package:kudipay/features/tier/presentation/controllers/tier_provider.dart';

class TierSelectionScreen extends ConsumerWidget {
  const TierSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierState = ref.watch(tierProvider);
    final currentTier = tierState.currentTier;

    final tiers = [
      UpgradeTier.basicTier(),
      UpgradeTier.proTier(),
      UpgradeTier.megaTier(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Your Tier',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Select the tier that works best for you',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Current Tier Indicator
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                border: Border.all(color: AppColors.primaryTeal),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryTeal,
                    size: AppLayout.scaleWidth(context, 20),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: Text(
                      'You are currently on ${_getTierName(currentTier)}',
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Tier Cards
            ...tiers.map((tier) => _buildTierCard(
                  context,
                  ref,
                  tier,
                  isCurrentTier: currentTier == tier.level,
                  canUpgrade: tier.level.index > currentTier.index,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    WidgetRef ref,
    UpgradeTier tier, {
    required bool isCurrentTier,
    required bool canUpgrade,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        border: Border.all(
          color: isCurrentTier ? tier.color : Colors.grey[300]!,
          width: isCurrentTier ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppLayout.scaleWidth(context, 10),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with tier icon and name
          Container(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppLayout.scaleWidth(context, 16)),
                topRight: Radius.circular(AppLayout.scaleWidth(context, 16)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: AppLayout.scaleWidth(context, 50),
                  height: AppLayout.scaleWidth(context, 50),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tier.icon,
                    size: AppLayout.scaleWidth(context, 28),
                    color: tier.color,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: GoogleFonts.openSans(
                          fontSize: AppLayout.fontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tier ${tier.tierNumber}',
                        style: GoogleFonts.openSans(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentTier)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 12),
                      vertical: AppLayout.scaleHeight(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: tier.color,
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 12)),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Benefits
          Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefits',
                  style: GoogleFonts.openSans(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                ...tier.benefits.map((benefit) => Padding(
                      padding: EdgeInsets.only(
                          bottom: AppLayout.scaleHeight(context, 8)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: AppLayout.scaleWidth(context, 16),
                            color: tier.color,
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 8)),
                          Expanded(
                            child: Text(
                              benefit.title,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          if (benefit.value != null)
                            Text(
                              benefit.value!,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    )),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentTier
                        ? null
                        : canUpgrade
                            ? () => _navigateToTierDetails(context, tier)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentTier
                          ? Colors.grey[300]
                          : canUpgrade
                              ? tier.color
                              : Colors.grey[300],
                      foregroundColor: isCurrentTier || !canUpgrade
                          ? Colors.grey[600]
                          : Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 12)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentTier
                          ? 'Current Tier'
                          : canUpgrade
                              ? 'Upgrade to ${tier.name}'
                              : 'View Details',
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTierDetails(BuildContext context, UpgradeTier tier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpgradeTierScreen(tier: tier),
      ),
    );
  }

  String _getTierName(TierLevel tier) {
    switch (tier) {
      case TierLevel.basic:
        return 'Basic Tribe';
      case TierLevel.pro:
        return 'Pro Tribe';
      case TierLevel.mega:
        return 'Mega Tribe';
    }
  }
}
