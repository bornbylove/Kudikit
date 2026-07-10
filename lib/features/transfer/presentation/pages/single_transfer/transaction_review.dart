import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/pin_entry_dialogue.dart';
import 'package:kudipay/provider/provider.dart';

class TransactionReviewBottomSheet extends ConsumerWidget {
  const TransactionReviewBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionReviewBottomSheet(),
    );
  }

  /// Returns up to 2 uppercase initials from a full name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(p2pTransferProvider);
    final data = state.transferData;
    final senderName = ref.watch(userProvider);
    final verificationState = ref.watch(identityVerificationProvider);
    final senderAccountNumber =
        verificationState.verificationData?.idNumber ?? '';
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 16),
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ───────────────────────────────────────────
              Center(
                child: Container(
                  width: AppLayout.scaleWidth(context, 40),
                  height: AppLayout.scaleHeight(context, 4),
                  margin: EdgeInsets.only(
                      bottom: AppLayout.scaleHeight(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 8),
                    height: AppLayout.scaleWidth(context, 8),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 2,
                      color: Colors.transparent,
                    ),
                  ),
                  Text(
                    'Kindly confirm',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: AppLayout.scaleWidth(context, 28),
                      height: AppLayout.scaleWidth(context, 28),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // ── Amount ──────────────────────────────────────────────
              Center(
                child: Text(
                  currencyFormat.format(data.amount ?? 0),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 32),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF389165),
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Details card ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCardRow(
                      context,
                      'Account number',
                      data.recipient?.accountNumber ?? '',
                      showDivider: true,
                    ),
                    _buildCardRow(
                      context,
                      'Name',
                      data.recipient?.name ?? '',
                      showDivider: true,
                    ),
                    _buildCardRow(
                      context,
                      'Bank',
                      data.recipient?.bank ?? 'Kudikit',
                      showDivider: data.note != null && data.note!.isNotEmpty,
                    ),
                    if (data.note != null && data.note!.isNotEmpty)
                      _buildCardRow(
                        context,
                        'Note',
                        data.note!,
                        showDivider: false,
                      ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Paying from label ────────────────────────────────────
              Text(
                'Paying from',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.black45,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 10)),

              // ── Sender card ──────────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 14),
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppLayout.scaleWidth(context, 20),
                      backgroundColor:
                          AppColors.primaryTeal.withValues(alpha: 0.15),
                      child: Text(
                        _initials(senderName),
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderAccountNumber.isNotEmpty
                                ? '${senderName.toUpperCase()}  $senderAccountNumber'
                                : senderName.toUpperCase(),
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF171515),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 4)),
                          Text(
                            currencyFormat.format(data.balance),
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // ── Send button (full width) ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    PinEntryBottomSheet.show(context);
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
                    'Send',
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

  Widget _buildCardRow(
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
            vertical: AppLayout.scaleHeight(context, 13),
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
}
