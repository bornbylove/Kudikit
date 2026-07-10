// lib/presentation/addmoney/transaction_receipt_screen.dart
//
// Transaction receipt screen — matches the updated Figma designs exactly.
//
// Two states:
//   • Success → green check circle on left, teal "successfully" keyword
//   • Failed  → red × circle on left,      red   "failed"       keyword
//
// The right circle always shows the bank logo pill (orange + "GTCO" style).
// Both share the same layout; only the icon, color, and copy differ.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/features/wallet/presentation/pages/addmoney/add_money_screen.dart';
import 'package:kudipay/provider/provider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

bool _isSuccess(String status) =>
    status.toLowerCase().contains('success') ||
    status.toLowerCase() == 'completed';

String _formatAmount(double amount) =>
    NumberFormat('#,##0.00', 'en_NG').format(amount);

String _formatDate(DateTime date) {
  final day = date.day;
  final suffix = (day >= 11 && day <= 13)
      ? 'th'
      : switch (day % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return DateFormat("MMM d'$suffix', yyyy HH:mm:ss").format(date);
}

// ─── Entry point ─────────────────────────────────────────────────────────────

class TransactionReceiptScreen extends ConsumerWidget {
  const TransactionReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(cardTopUpProvider).receipt;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _receiptAppBar(context),
      body: receipt == null
          ? const Center(child: Text('No receipt available'))
          : _ReceiptBody(receipt: receipt),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

PreferredSizeWidget _receiptAppBar(BuildContext context) => AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      title: Text(
        'Transaction Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              Icons.headset_mic_outlined,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 24),
            ),
            onPressed: () {/* Contact support */},
          ),
        ),
      ],
    );

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ReceiptBody extends StatelessWidget {
  final TransactionReceipt receipt;
  const _ReceiptBody({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final success = _isSuccess(receipt.status);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 20),
        vertical: AppLayout.scaleHeight(context, 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Overlapping circles ──────────────────────────────────────────
          _StatusCircles(
            success: success,
            bankLabel: _bankShortLabel(receipt.payingBank),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // ── Status sentence ──────────────────────────────────────────────
          _StatusSentence(receipt: receipt, success: success),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // ── Amount ───────────────────────────────────────────────────────
          Text(
            '₦${_formatAmount(receipt.amount)}',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 32),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // ── Details card ─────────────────────────────────────────────────
          _DetailsCard(receipt: receipt),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // ── Action buttons ───────────────────────────────────────────────
          _ActionButtons(success: success),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  /// Derive a short bank acronym from the payingBank string.
  static String _bankShortLabel(String payingBank) {
    // e.g. "Guaranty Trust Bank" → "GTCO", "Opay" → "OPay"
    final known = {
      'guaranty': 'GTCO',
      'gtbank': 'GTCO',
      'gtco': 'GTCO',
      'opay': 'OPay',
      'kuda': 'KUDA',
      'zenith': 'ZEN',
      'access': 'ACC',
      'uba': 'UBA',
      'first bank': 'FBN',
      'firstbank': 'FBN',
      'sterling': 'STLG',
      'wema': 'WEMA',
      'union': 'UBN',
      'fidelity': 'FDL',
      'heritage': 'HBN',
      'stanbic': 'SIBT',
      'polaris': 'POL',
    };
    final lower = payingBank.toLowerCase();
    for (final entry in known.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Fallback: first 4 chars uppercased
    return payingBank.length >= 4
        ? payingBank.substring(0, 4).toUpperCase()
        : payingBank.toUpperCase();
  }
}

// ─── Overlapping circles ──────────────────────────────────────────────────────

class _StatusCircles extends StatelessWidget {
  final bool success;
  final String bankLabel;

  const _StatusCircles({required this.success, required this.bankLabel});

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.scaleWidth(context, 64);
    final overlap = AppLayout.scaleWidth(context, 20);

    return SizedBox(
      width: size * 2 - overlap,
      height: size,
      child: Stack(
        children: [
          // ── Left: status icon circle ───────────────────────────────────
          Positioned(
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFF22C487) // green
                    : const Color(0xFFE53935), // red
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF9F9F9), width: 2),
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                color: Colors.white,
                size: AppLayout.scaleWidth(context, 26),
              ),
            ),
          ),

          // ── Right: bank logo circle ────────────────────────────────────
          Positioned(
            left: size - overlap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35), // orange — matches design
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF9F9F9), width: 2),
              ),
              child: Center(
                child: Text(
                  bankLabel,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(
                        context, bankLabel.length > 4 ? 8 : 10),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
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

// ─── Status sentence ──────────────────────────────────────────────────────────

class _StatusSentence extends StatelessWidget {
  final TransactionReceipt receipt;
  final bool success;

  const _StatusSentence({required this.receipt, required this.success});

  @override
  Widget build(BuildContext context) {
    // Extract recipient name from transactionType e.g. "Transfer to PETER Daniel"
    // or fall back to creditedTo
    final recipient = receipt.creditedTo.isNotEmpty
        ? receipt.creditedTo
        : receipt.transactionType;

    final keyword = success ? 'successfully' : 'failed';
    final keywordColor =
        success ? const Color(0xFF22C487) : const Color(0xFFE53935);

    // Build: "Transfer to [recipient] is [keyword]\ncompleted" (success)
    //        "Transfer to [recipient] [keyword] to be\ncompleted" (failed)
    final prefix =
        success ? 'Transfer to $recipient is ' : 'Transfer to $recipient ';
    final suffix = success ? '\ncompleted' : ' to be\ncompleted';

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          height: 1.4,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: keyword,
            style: TextStyle(
              color: keywordColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }
}

// ─── Details card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final TransactionReceipt receipt;

  const _DetailsCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 20),
        vertical: AppLayout.scaleHeight(context, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 15),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 4)),

          // Recipient Details — two-line value
          _DetailRow(
            context: context,
            label: 'Recipient Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  receipt.creditedTo,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                Text(
                  receipt.payingBank,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),

          _Divider(),

          // Transaction No. — with copy icon
          _DetailRow(
            context: context,
            label: 'Transaction No.',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    receipt.transactionNumber,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 6)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: receipt.transactionNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Transaction ID copied'),
                        backgroundColor: AppColors.primaryTeal,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_outlined,
                    size: AppLayout.scaleWidth(context, 15),
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          _Divider(),

          // Payment Type
          _DetailRow(
            context: context,
            label: 'Payment Type',
            child: Text(
              receipt.transactionType,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          _Divider(),

          // Transaction Date
          _DetailRow(
            context: context,
            label: 'Transaction Date',
            child: Text(
              _formatDate(receipt.transactionDate),
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 8)),
        ],
      ),
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final Widget child;

  const _DetailRow({
    required this.context,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.grey[200], height: 1, thickness: 1);
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool success;

  const _ActionButtons({required this.success});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Share
        Expanded(
          child: SizedBox(
            height: AppLayout.scaleHeight(context, 52),
            child: OutlinedButton.icon(
              onPressed: () {/* Share receipt */},
              icon: Icon(
                Icons.share_outlined,
                size: AppLayout.scaleWidth(context, 18),
                color: AppColors.primaryTeal,
              ),
              label: Text(
                'Share',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side:
                    const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: AppLayout.scaleWidth(context, 16)),

        // Download / Retry
        Expanded(
          child: SizedBox(
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton.icon(
              onPressed: () {
                if (success) {
                  // Download receipt PDF
                } else {
                  // Failed → go back to retry
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                  );
                }
              },
              icon: Icon(
                success ? Icons.download_outlined : Icons.refresh_rounded,
                size: AppLayout.scaleWidth(context, 18),
                color: Colors.white,
              ),
              label: Text(
                success ? 'Download' : 'Try Again',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    success ? AppColors.primaryTeal : const Color(0xFFE53935),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
