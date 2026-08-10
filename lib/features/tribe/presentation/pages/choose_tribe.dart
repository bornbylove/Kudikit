import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/tribe/domain/entities/tribe_card.dart';
import 'package:kudipay/features/kyc/presentation/pages/kyc_flow_manager.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/tier/presentation/controllers/tier_provider.dart';

class TribeScreen extends ConsumerStatefulWidget {
  const TribeScreen({super.key});

  @override
  ConsumerState<TribeScreen> createState() => _KudikitTribeScreenState();
}

class _KudikitTribeScreenState extends ConsumerState<TribeScreen> {
  // 0 = Tier 1 (Basic), 1 = Tier 2 (Pro), 2 = Tier 3 (Mega)
  int? selectedTribe;
  bool _isSaving = false;

  // ---------------------------------------------------------------------------
  // Converts the 0-based selectedTribe index to a real tier number (1, 2, 3).
  // ---------------------------------------------------------------------------
  int get _selectedTierNumber => (selectedTribe ?? 0) + 1;

  Future<void> _onContinue() async {
    if (selectedTribe == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Tell the backend the chosen tier. It returns the tier actually
      //    granted, which can be lower than requested while KYC is pending.
      final grantedTier = await ref.read(authProvider.notifier).selectTier(
            tierNumber: _selectedTierNumber,
          );

      // 2. Persist what the server granted — not what was asked for — so the
      //    app never shows a tier whose limits the backend has not unlocked.
      await ref.read(tierProvider.notifier).setTierFromOnboarding(grantedTier);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycFlowManager()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save tier. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 40),
                    height: AppLayout.scaleWidth(context, 40),
                    child: CircularProgressIndicator(
                      value: 0.80,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '80%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your Kudikit Tribe',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the account type that fits your needs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tier 1 — Basic Tribe ───────────────────────────────
                  TribeCard(
                    icon: Icons.shield,
                    iconColor: AppColors.primaryTeal,
                    title: 'Basic Tribe',
                    tier: 'Tier 1',
                    subtitle: 'For everyday transactions',
                    requirements: const ['Valid ID (NIN / BVN)'],
                    limits: const [
                      'Daily Send Limit: ₦50,000',
                      'Daily Receive Limit: ₦100,000',
                      'Maximum Balance: ₦300,000',
                      'Single Transaction Max: ₦50,000',
                    ],
                    isSelected: selectedTribe == 0,
                    isExpanded: selectedTribe == 0,
                    onTap: () => setState(() {
                      selectedTribe = selectedTribe == 0 ? null : 0;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Tier 2 — Pro Tribe ────────────────────────────────
                  TribeCard(
                    icon: Icons.star,
                    iconColor: const Color(0xFFFFA726),
                    title: 'Pro Tribe',
                    tier: 'Tier 2',
                    subtitle: 'For growing your finances',
                    requirements: const [
                      'NIN & BVN',
                      'Face verification',
                      'Address verification',
                    ],
                    limits: const [
                      'Daily Send Limit: ₦500,000',
                      'Daily Receive Limit: ₦1,000,000',
                      'Maximum Balance: ₦3,000,000',
                    ],
                    isSelected: selectedTribe == 1,
                    isExpanded: selectedTribe == 1,
                    onTap: () => setState(() {
                      selectedTribe = selectedTribe == 1 ? null : 1;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Tier 3 — Mega Tribe ───────────────────────────────
                  TribeCard(
                    icon: Icons.verified,
                    iconColor: const Color(0xFF7E57C2),
                    title: 'Mega Tribe',
                    tier: 'Tier 3',
                    subtitle: 'For high-value transactions',
                    requirements: const [
                      'NIN & BVN',
                      'Face verification',
                      'Address Verification (Agent visit)',
                      'Utility Bill',
                    ],
                    limits: const [
                      'Daily Send Limit: ₦5,000,000',
                      'Daily Receive Limit: Unlimited',
                      'Maximum Balance: Unlimited',
                      'Single Transaction Max: ₦5,000,000',
                    ],
                    isSelected: selectedTribe == 2,
                    isExpanded: selectedTribe == 2,
                    onTap: () => setState(() {
                      selectedTribe = selectedTribe == 2 ? null : 2;
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Continue button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (selectedTribe != null && !_isSaving) ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor:
                      AppColors.primaryTeal.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
