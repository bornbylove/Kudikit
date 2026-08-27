import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tribe/tribe_card.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';

class TribeScreen extends ConsumerStatefulWidget {
  const TribeScreen({Key? key}) : super(key: key);

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

    // SLICE 6 (MO-1): tier selection is SERVER-AUTHORITATIVE. POST
    // /auth/select-tier persists pendingTier on the auth-service and returns the
    // authoritative UserResponse (tier / pendingTier / registrationComplete).
    // Local persistence below remains a display/cache fallback only — it must
    // never override server state (see KycFlowManager.effectiveTier).
    try {
      await ref
          .read(authProvider.notifier)
          .selectTier(_selectedTierNumber);
    } on Exception {
      // Best-effort: a transient network failure must not block onboarding —
      // local state keeps the flow usable and the next reconcile re-syncs.
    }

    // 1. Persist the chosen tier so tierProvider (and the home / profile
    //    screens that watch it) always shows the correct tier number.
    await ref
        .read(tierProvider.notifier)
        .setTierFromOnboarding(_selectedTierNumber);

    // 2. Also persist selectedTier on the UserModel so it survives re-login.
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref
          .read(authProvider.notifier)
          .updateUser(user.copyWith(selectedTier: _selectedTierNumber));
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // 3. Route based on tier:
    //    Tier 1 → KycFlowManager (will route straight to ID screen, then home)
    //    Tier 2 / 3 → KycFlowManager (will route through full KYC steps)
    //
    //    KycFlowManager reads both the tier AND the user's KYC flags, so it
    //    automatically decides the correct next screen for every tier.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycFlowManager()),
    );
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
                          Color(0xFF069494)),
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
                    iconColor: const Color(0xFF069494),
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
                  backgroundColor: const Color(0xFF069494),
                  disabledBackgroundColor:
                      const Color(0xFF069494).withOpacity(0.5),
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