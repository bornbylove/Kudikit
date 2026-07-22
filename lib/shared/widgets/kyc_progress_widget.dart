import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';

class KycProgressWidget extends ConsumerWidget {
  final bool showNavigationButtons;
  final bool compact;

  const KycProgressWidget({
    super.key,
    this.showNavigationButtons = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final kycProgress = ref.watch(kycProgressProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactView(context, user, kycProgress);
    }

    return _buildFullView(context, ref, user, kycProgress);
  }

  Widget _buildCompactView(BuildContext context, user, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KYC Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
            ),
          ),
          if (!user.isKycComplete) ...[
            const SizedBox(height: 8),
            Text(
              _getNextStepMessage(user),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView(
      BuildContext context, WidgetRef ref, user, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal,
            Color(0xFF4DB6AC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KYC Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          _buildKycStep(
            context,
            ref,
            icon: Icons.email_outlined,
            title: 'Email Verification',
            isCompleted: user.isEmailVerified,
            onTap: null, // Email already verified during signup
          ),
          const SizedBox(height: 12),
          _buildKycStep(
            context,
            ref,
            icon: Icons.person_outline,
            title: 'Selfie Capture',
            isCompleted: user.isSelfieVerified,
            onTap: showNavigationButtons && !user.isSelfieVerified
                ? () =>
                    Navigator.pushNamed(context, AppRoutes.selfieInstructions)
                : null,
          ),
          const SizedBox(height: 12),
          _buildKycStep(
            context,
            ref,
            icon: Icons.credit_card,
            title: '/NIN Verification',
            isCompleted: user.isVerified,
            onTap: showNavigationButtons && !user.isVerified
                ? () => Navigator.pushNamed(context, AppRoutes.chooseId)
                : null,
          ),
          const SizedBox(height: 12),
          _buildKycStep(
            context,
            ref,
            icon: Icons.location_on_outlined,
            title: 'Address Verification',
            isCompleted: user.isAddressVerified,
            onTap: showNavigationButtons && !user.isAddressVerified
                ? () => Navigator.pushNamed(context, AppRoutes.verifyAddress)
                : null,
          ),
          const SizedBox(height: 12),
          // _buildKycStep(
          //   context,
          //   ref,
          //   icon: Icons.upload_file_outlined,
          //   title: 'Document Upload',
          //   isCompleted: user.isDocumentVerified,
          //   onTap: showNavigationButtons && !user.isDocumentVerified
          //       ? () => Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (_) => const UploadIdCardScreen(),
          //             ),
          //           )
          //       : null,
          // ),
          if (user.isKycComplete) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'KYC Verification Complete!\nYou can now access all features.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKycStep(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? AppColors.primaryTeal : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (onTap != null && !isCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              )
            else if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getNextStepMessage(dynamic user) {
    if (!user.isSelfieVerified) return 'Next: Complete selfie capture';
    if (!user.isVerified) return 'Next: Verify your /NIN';
    if (!user.isAddressVerified) return 'Next: Verify your address';
    if (!user.isDocumentVerified) return 'Next: Upload ID document';
    return 'Almost there!';
  }
}
