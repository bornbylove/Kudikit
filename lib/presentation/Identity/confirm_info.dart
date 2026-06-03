import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/presentation/transactionpin/transaction_pin_screen.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';

// =============================================================================
// ConfirmInfoScreen
// -----------------------------------------------------------------------------
// Last KYC data-entry step before PIN creation. Displays the user's verified
// identity details for final confirmation.
//
// FLOW  (all tiers):
//   [ID Verification] --? ConfirmInfoScreen --[Submit]--? CreateTransactionPinScreen
//                                             ?
//                                         [Edit Info] ? pop back
//
// The circular progress indicator is fixed at 100% — this is the last step
// before the user creates their transaction PIN and reaches the dashboard.
// =============================================================================

class ConfirmInfoScreen extends ConsumerStatefulWidget {
  final UserInfo userInfo;

  const ConfirmInfoScreen({
    super.key,
    required this.userInfo,
  });

  @override
  ConsumerState<ConfirmInfoScreen> createState() => _ConfirmInfoScreenState();
}

class _ConfirmInfoScreenState extends ConsumerState<ConfirmInfoScreen> {
  bool _isSubmitting = false;

  // ---------------------------------------------------------------------------
  // SUBMIT — calls AuthService, updates KYC flags, then pushes PIN screen.
  // ---------------------------------------------------------------------------
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final authService = ref.read(authServiceProvider);
      final success = await authService.submitUserInfo(widget.userInfo);

      if (!mounted) return;

      if (success) {
        // Persist BVN verification on the user model so KycFlowManager
        // won't re-route the user to this step on re-entry.
        await ref.read(authProvider.notifier).updateKycStatus(
              isBvnVerified: true,
              bvn: widget.userInfo.bvn,
            );

        if (!mounted) return;

        // pushReplacement so the user cannot go back to confirm screen
        // from the PIN creation screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateTransactionPinScreen(),
          ),
        );
      } else {
        _showError('Failed to submit your information. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!_isSubmitting) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundScreen,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              // -- Scrollable content -----------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),

                      // Title
                      Text(
                        'Confirm your Info',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 28),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 10)),

                      // Subtitle
                      Text(
                        'Please confirm that these details are yours and correct. '
                        'Once submitted, they cannot be changed',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: AppColors.textGrey,
                          height: 1.55,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 32)),

                      // -- Info card group ----------------------------------
                      _buildInfoCard(context),

                      SizedBox(height: AppLayout.scaleHeight(context, 40)),
                    ],
                  ),
                ),
              ),

              // -- Sticky bottom buttons --------------------------------------
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR — back arrow left, 100% circular progress indicator right
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundScreen,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: AppLayout.scaleWidth(context, 56),
      leading: _isSubmitting
          ? const SizedBox()
          : IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textDark,
                size: AppLayout.scaleWidth(context, 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
          child: Center(
            child: SizedBox(
              width: AppLayout.scaleWidth(context, 42),
              height: AppLayout.scaleWidth(context, 42),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 32),
                    height: AppLayout.scaleWidth(context, 32),
                    child: CircularProgressIndicator(
                     value: 1.0,
                      strokeWidth: AppLayout.scaleWidth(context, 2.5),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  Text(
                    '100%',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 9.5),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INFO CARD — all four rows grouped in a single card with dividers
  // ---------------------------------------------------------------------------
  Widget _buildInfoCard(BuildContext context) {
    final rows = [
      _RowData(label: 'First Name', value: widget.userInfo.firstName),
      _RowData(label: 'Last Name', value: widget.userInfo.lastName),
      _RowData(label: 'BVN', value: widget.userInfo.maskedBvn),
      _RowData(
        label: 'Date of Birth',
        value: _formatDate(widget.userInfo.dateOfBirth),
        isLast: true,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Column(
        children: rows
            .map((r) => _InfoRow(
                  label: r.label,
                  value: r.value,
                  isLast: r.isLast,
                ))
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildBottomActions(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Submit
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 54),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor:
                      AppColors.primaryTeal.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 28),
                    ),
                  ),
                ),
                child: _isSubmitting
                    ? const AppLoadingIndicator.button()
                    : Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Edit Info
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 54),
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F5E9),
                  foregroundColor: AppColors.primaryTeal,
                  side: BorderSide.none,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 28),
                    ),
                  ),
                ),
                child: Text(
                  'Edit Info',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _InfoRow  — a single label/value row inside the grouped info card.
// =============================================================================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F4),
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFDDE8E2),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal data holder — keeps `_buildInfoCard` readable.
class _RowData {
  final String label;
  final String value;
  final bool isLast;
  const _RowData(
      {required this.label, required this.value, this.isLast = false});
}
