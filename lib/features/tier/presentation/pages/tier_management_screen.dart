import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';
import 'package:kudipay/presentation/tier/tier_selection_screen.dart';

class TierManagementScreen extends ConsumerWidget {
  const TierManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierState = ref.watch(tierProvider);
    final currentTierObject = tierState.getTierObject();
    final nextTier = tierState.getNextTier();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
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
          'Tier Management',
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
            // Current Tier Card
            _buildCurrentTierCard(context, currentTierObject, tierState),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Tier Benefits
            _buildBenefitsSection(context, currentTierObject),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Upgrade Section
            if (nextTier != null) ...[
              _buildUpgradeSection(context, ref, nextTier),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
            ],

            // Change Tier Button
            _buildChangeTierButton(context),

            // Last Upgraded Info
            if (tierState.lastUpgraded != null) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              _buildLastUpgradedInfo(context, tierState.lastUpgraded!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTierCard(
      BuildContext context, UpgradeTier tier, TierState tierState) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tier.color, tier.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.3),
            blurRadius: AppLayout.scaleWidth(context, 15),
            offset: Offset(0, AppLayout.scaleHeight(context, 5)),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 60),
                height: AppLayout.scaleWidth(context, 60),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tier.icon,
                  size: AppLayout.scaleWidth(context, 32),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Current Tier',
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 12),
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),
                    Text(
                      tier.name,
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 22),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tier ${tier.tierNumber}',
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context, UpgradeTier tier) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppLayout.scaleWidth(context, 10),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Benefits',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          ...tier.benefits.map((benefit) => Padding(
                padding:
                    EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
                child: Row(
                  children: [
                    Container(
                      width: AppLayout.scaleWidth(context, 32),
                      height: AppLayout.scaleWidth(context, 32),
                      decoration: BoxDecoration(
                        color: tier.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: AppLayout.scaleWidth(context, 18),
                        color: tier.color,
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit.title,
                            style: GoogleFonts.openSans(
                              fontSize: AppLayout.fontSize(context, 14),
                              color: Colors.grey[700],
                            ),
                          ),
                          if (benefit.value != null)
                            Text(
                              benefit.value!,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 16),
                                fontWeight: FontWeight.bold,
                                color: tier.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUpgradeSection(
      BuildContext context, WidgetRef ref, UpgradeTier nextTier) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        border: Border.all(color: nextTier.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppLayout.scaleWidth(context, 10),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                color: nextTier.color,
                size: AppLayout.scaleWidth(context, 24),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Text(
                'Upgrade Available',
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          Text(
            'Upgrade to ${nextTier.name}',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: nextTier.color,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            'Unlock higher limits and more features',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TierSelectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: nextTier.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                ),
                elevation: 0,
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeTierButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TierSelectionScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: AppLayout.scaleHeight(context, 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          ),
          side: const BorderSide(color: Color(0xFF069494), width: 2),
        ),
        child: Text(
          'View All Tiers',
          style: GoogleFonts.openSans(
            fontSize: AppLayout.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF069494),
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpgradedInfo(BuildContext context, DateTime lastUpgraded) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(lastUpgraded);

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
            size: AppLayout.scaleWidth(context, 20),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              'Last upgraded on $formattedDate',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
