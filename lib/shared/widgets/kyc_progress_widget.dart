
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
// import 'package:kudipay/presentation/Identity/upload_ID.dart';
import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';


class KycProgressWidget extends ConsumerWidget {
  final bool showNavigationButtons;
  final bool compact;

  const KycProgressWidget({
    Key? key,
    this.showNavigationButtons = true,
    this.compact = false,
  }) : super(key: key);

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
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
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

  Widget _buildFullView(BuildContext context, WidgetRef ref, user, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF069494),
            Color(0xFF4DB6AC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF069494).withValues(alpha: 0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelfieInstructionsScreen(),
                      ),
                    )
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
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IdVerificationScreen(),
                      ),
                    )
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
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressVerificationScreen(),
                      ),
                    )
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
                      color: Color(0xFF069494),
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
                color: isCompleted
                    ? const Color(0xFF069494)
                    : Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF069494),
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

  String _getNextStepMessage(user) {
    if (!user.isSelfieVerified) return 'Next: Complete selfie capture';
    if (!user.isVerified) return 'Next: Verify your /NIN';
    if (!user.isAddressVerified) return 'Next: Verify your address';
    if (!user.isDocumentVerified) return 'Next: Upload ID document';
    return 'Almost there!';
  }
}