import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transaction_detail.dart';

/// Full-screen success (or error) page shown after a transfer completes.
/// Navigated to via [Navigator.pushReplacement] from [ProcessingPaymentScreen].
class TransactionSuccessBottomSheet extends ConsumerStatefulWidget {
  const TransactionSuccessBottomSheet({super.key});

  /// Legacy modal helper kept for any callers that still reference it.
  static void show(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TransactionSuccessBottomSheet(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  ConsumerState<TransactionSuccessBottomSheet> createState() =>
      _TransactionSuccessBottomSheetState();
}

class _TransactionSuccessBottomSheetState
    extends ConsumerState<TransactionSuccessBottomSheet> {
  bool _addToFavourite = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);

    if (state.transactionResult == null) {
      return _buildErrorScaffold(context, 'Transaction data is not available');
    }

    if (state.transferData.recipient == null) {
      return _buildErrorScaffold(context, 'Recipient information is missing');
    }

    final result = state.transactionResult!;
    final recipient = state.transferData.recipient!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 24),
            vertical: AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // ── Success icon ─────────────────────────────────────────
              Container(
                width: AppLayout.scaleWidth(context, 72),
                height: AppLayout.scaleWidth(context, 72),
                decoration: const BoxDecoration(
                  color: Color(0xFF389165),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: AppLayout.scaleWidth(context, 38),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // ── Amount ───────────────────────────────────────────────
              Text(
                '-${_currencyFormat.format(result.amount)}',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 32),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 12)),

              // ── Success message ──────────────────────────────────────
              Text(
                'Transfer to ${recipient.name.toUpperCase()} is successfully completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // ── Transaction details card ──────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Transaction Type',
                      result.transactionType,
                      showDivider: true,
                    ),
                    _buildDetailRow(
                      context,
                      'Paying Bank',
                      '${result.payingBank}\n(${result.payingBankAccount})',
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Add to favourite toggle ───────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add to favourite',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _addToFavourite,
                      onChanged: (value) {
                        setState(() => _addToFavourite = value);
                      },
                      activeThumbColor: const Color(0xFF389165),
                      activeTrackColor:
                          const Color(0xFF389165).withValues(alpha: 0.35),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // ── Action buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _navigateToDetails(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 15),
                        ),
                        side: const BorderSide(
                          color: AppColors.primaryTeal,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDone(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 15),
                        ),
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error scaffold ──────────────────────────────────────────────────────
  Widget _buildErrorScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 24),
            vertical: AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 72),
                height: AppLayout.scaleWidth(context, 72),
                decoration: const BoxDecoration(
                  color: Color(0xFFF44336),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: AppLayout.scaleWidth(context, 38),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(p2pTransferProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppLayout.scaleHeight(context, 15),
                    ),
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go Home',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.black45,
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 16)),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  void _navigateToDetails(BuildContext context) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionDetailsScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to navigate to details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDone(BuildContext context) {
    try {
      if (_addToFavourite) {
        ref.read(p2pTransferProvider.notifier).addFavourite();
      }
      ref.read(p2pTransferProvider.notifier).reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Error in done handler: $e');
      Navigator.of(context).pop();
    }
  }
}
