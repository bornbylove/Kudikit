import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/core/navigation/navigation_helpers.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/features/identity/presentation/pages/choose_id.dart';
import 'package:kudipay/features/identity/presentation/pages/upload_id.dart';
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
// PRD-COMPLIANT ROUTING TABLE (v2 � fixed from original):
// -----------------------------------------------------------------------------
// Tier 1 (Basic)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN OR NIN verification    [isBvnVerified]
//   ? Confirm Info ? PIN ? Account Ready ? Dashboard
//
// Tier 2 (Pro)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN AND NIN verification   [isBvnVerified]
//   3. ID document upload         [isDocumentVerified]
//   ? Confirm Info ? PIN ? Account Ready ? Dashboard
//
// Tier 3 (Mega)
//   1. Selfie verification        [isSelfieVerified]
//   2. BVN AND NIN verification   [isBvnVerified]
//   3. ID document upload         [isDocumentVerified]
//   4. Address + utility bill     [isAddressVerified]
//   ? Confirm Info ? PIN ? Account Ready ? Dashboard
//
// NOTE: ConfirmInfoScreen, CreateTransactionPinScreen, and AccountReadyScreen
// are NOT routed from here. They are pushed sequentially from within each
// preceding screen � this manager only routes to the first incomplete step.
// =============================================================================

class KycFlowManager extends ConsumerWidget {
  const KycFlowManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tierState = ref.watch(tierProvider);
    final connectivityState = ref.watch(connectivityStateProvider);

    // -- Offline guard --------------------------------------------------------
    if (!connectivityState.isConnected) {
      return _OfflineScreen(
        onRetry: () => ref.read(connectivityStateProvider.notifier).refresh(),
        onBack: () => Navigator.pop(context),
      );
    }

    // -- Loading guard --------------------------------------------------------
    if (user == null || tierState.isLoading) {
      return const _LoadingScreen(message: 'Loading your information...');
    }

    // -- Resolve the next incomplete step and navigate ------------------------
    final tier = tierState.currentTier;
    final nextScreen = _resolveNextScreen(tier, user);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    });

    // Transitional placeholder shown for one frame while navigation is queued
    return _LoadingScreen(message: _loadingMessage(tier, user));
  }

  // ---------------------------------------------------------------------------
  // ROUTING LOGIC
  // Walk each tier's funnel top-to-bottom. Return the first screen whose
  // prerequisite flag is NOT yet set on the user model.
  // ---------------------------------------------------------------------------
  Widget _resolveNextScreen(TierLevel tier, dynamic user) {
    switch (tier) {
      // -- Tier 1 (Basic) -----------------------------------------------------
      // Steps: Selfie ? BVN or NIN
      case TierLevel.basic:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified) return const IdVerificationScreen();
        return const MainShellRedirect();

      // -- Tier 2 (Pro) -------------------------------------------------------
      // Steps: Selfie ? BVN AND NIN ? ID document upload
      case TierLevel.pro:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified) return const IdVerificationScreen();
        if (!user.isDocumentVerified) return const UploadIdCardScreen();
        return const MainShellRedirect();

      // -- Tier 3 (Mega) ------------------------------------------------------
      // Steps: Selfie ? BVN AND NIN ? ID document upload ? Address
      case TierLevel.mega:
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified) return const IdVerificationScreen();
        if (!user.isDocumentVerified) return const UploadIdCardScreen();
        if (!user.isAddressVerified) return const AddressVerificationScreen();
        return const MainShellRedirect();
    }
  }

  // ---------------------------------------------------------------------------
  // Human-readable loading message shown during the one-frame transition
  // ---------------------------------------------------------------------------
  String _loadingMessage(TierLevel tier, dynamic user) {
    switch (tier) {
      case TierLevel.basic:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified) return 'Preparing identity verification...';
        return 'Preparing your dashboard...';

      case TierLevel.pro:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified) return 'Preparing identity verification...';
        if (!user.isDocumentVerified) return 'Preparing document upload...';
        return 'Preparing your dashboard...';

      case TierLevel.mega:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified) return 'Preparing identity verification...';
        if (!user.isDocumentVerified) return 'Preparing document upload...';
        if (!user.isAddressVerified) return 'Preparing address verification...';
        return 'Preparing your dashboard...';
    }
  }
}

// =============================================================================
// _LoadingScreen � shown for one frame while navigation is pending, and also
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
// _OfflineScreen � shown when there is no internet connection.
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
              // -- Icon ----------------------------------------------------
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

              // -- Title ----------------------------------------------------
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

              // -- Check Connection button ----------------------------------
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

              // -- Go Back --------------------------------------------------
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

              // -- Tips card ------------------------------------------------
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
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
            '�  ',
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
