import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/app_route.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';

import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';

// =============================================================================
// AccountReadyScreen
// -----------------------------------------------------------------------------
// Shown after the user successfully creates their transaction PIN. This is the
// final screen in the onboarding / KYC funnel before the main dashboard.
//
// WHAT IT SHOWS:
//   ✓  Green check circle (animated scale-in)
//   ✓  "Congratulations! Your account is ready"
//   ✓  Account number  (copyable)
//   ✓  Account name    (from wallet state)
//   ✓  Account tier    (from tier state) + "Upgrade for Higher Limits" badge
//   ✓  "Proceed to Dashboard" primary button
//
// NAVIGATION:
//   Pressing "Proceed to Dashboard" pushes BottomNavBar and removes the
//   entire onboarding stack — the user cannot go back.
//
// DESIGN REFERENCE:
//   Image 2 in the PRD — teal/green palette, card with copy icon,
//   upgrade badge for Tier 1 users.
// =============================================================================

class AccountReadyScreen extends ConsumerStatefulWidget {
  const AccountReadyScreen({super.key});

  @override
  ConsumerState<AccountReadyScreen> createState() => _AccountReadyScreenState();
}

class _AccountReadyScreenState extends ConsumerState<AccountReadyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Slight delay so the screen is fully laid out before the animation fires
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Copies the account number to the clipboard and shows a brief snackbar.
  // ---------------------------------------------------------------------------
  void _copyAccountNumber(String accountNumber) {
    Clipboard.setData(ClipboardData(text: accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account number copied!',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 20),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Returns a human-readable tier label, e.g. "Tier 1", "Tier 2", "Tier 3"
  // ---------------------------------------------------------------------------
  String _tierLabel(TierLevel tier) {
    switch (tier) {
      case TierLevel.basic:
        return 'Tier 1';
      case TierLevel.pro:
        return 'Tier 2';
      case TierLevel.mega:
        return 'Tier 3';
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final tierState = ref.watch(tierProvider);
    final tier = tierState.currentTier;

    // Derive account details — fall back to safe placeholders during loading
    final accountNumber =
        walletState.accountNumber.isNotEmpty ? walletState.accountNumber : '—';
    final accountName =
        walletState.accountName.isNotEmpty ? walletState.accountName : '—';
    final isMaxTier = tier == TierLevel.mega;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundScreen,
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 24),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: AppLayout.scaleHeight(context, 60)),

                      // ── Animated check circle ──────────────────────────
                      AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (_, child) => Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: AppLayout.scaleWidth(context, 72),
                          height: AppLayout.scaleWidth(context, 72),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: AppLayout.scaleWidth(context, 36),
                          ),
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 28)),

                      // ── Heading ────────────────────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Text(
                              'Congratulations! Your account\nis ready',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 12)),
                            Text(
                              'Your account details are shown below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 14),
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 36)),

                      // ── Account details card ───────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildAccountCard(
                          context,
                          accountNumber: accountNumber,
                          accountName: accountName,
                          tier: tier,
                          isMaxTier: isMaxTier,
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 40)),
                    ],
                  ),
                ),
              ),

              // ── Sticky "Proceed to Dashboard" button ─────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: _buildProceedButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT DETAILS CARD
  // ---------------------------------------------------------------------------
  Widget _buildAccountCard(
    BuildContext context, {
    required String accountNumber,
    required String accountName,
    required TierLevel tier,
    required bool isMaxTier,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F4),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        border: Border.all(
          color: const Color(0xFFDDE8E2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account Number row ──────────────────────────────────────────
          _buildDetailSection(
            context,
            label: 'Account Number',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  accountNumber,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                // Copy icon
                GestureDetector(
                  onTap: accountNumber == '—'
                      ? null
                      : () => _copyAccountNumber(accountNumber),
                  child: Container(
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 6)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 6)),
                      border: Border.all(
                        color: const Color(0xFFDDE8E2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: AppLayout.scaleWidth(context, 16),
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(context),

          // ── Account Name ────────────────────────────────────────────────
          _buildDetailSection(
            context,
            label: 'Account name',
            child: Text(
              accountName,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),

          _buildDivider(context),

          // ── Account Tier row with optional upgrade badge ─────────────────
          _buildDetailSection(
            context,
            label: 'Account Tier',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tierLabel(tier),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (!isMaxTier)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 10),
                      vertical: AppLayout.scaleHeight(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEFE4),
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 20)),
                    ),
                    child: Text(
                      'Upgrade for Higher Limits',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 10),
                        fontWeight: FontWeight.w500,
                        color: AppColors.checkGreen,
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

  // ---------------------------------------------------------------------------
  // CARD SECTION HELPER — label on top, content below
  // ---------------------------------------------------------------------------
  Widget _buildDetailSection(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 12),
            color: AppColors.textGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 6)),
        child,
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 14)),
      child: const Divider(
        color: Color(0xFFDDE8E2),
        height: 1,
        thickness: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROCEED TO DASHBOARD BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildProceedButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 28),
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundScreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 54),
          child: ElevatedButton(
            onPressed: () {
              // Remove the entire onboarding / KYC stack and land on the
              // main dashboard. The user cannot navigate back.
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bottomNav, (_) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppLayout.scaleWidth(context, 28),
                ),
              ),
            ),
            child: Text(
              'Proceed to Dashboard',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}