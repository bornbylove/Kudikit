import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transaction_review.dart';
import 'package:kudipay/provider/provider.dart';

class ConfirmTransferBottomSheet extends ConsumerWidget {
  const ConfirmTransferBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConfirmTransferBottomSheet(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(p2pTransferProvider);
    final senderName = ref.watch(userProvider);
    final verificationState = ref.watch(identityVerificationProvider);
    final senderAccountNumber =
        verificationState.verificationData?.idNumber ?? '';

    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    final recipient = state.transferData.recipient;
    final balance = state.transferData.balance;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 20),
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

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Amount ──────────────────────────────────────────────
              Center(
                child: Text(
                  currencyFormat.format(state.transferData.amount ?? 0),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 32),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF389165),
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Recipient details card ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    // Row 1: Account details
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 15),
                        vertical: AppLayout.scaleHeight(context, 13),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account details',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            '${recipient?.accountNumber ?? ''}'
                            '${(recipient?.bank != null && recipient!.bank!.isNotEmpty) ? ' | ${recipient.bank}' : ''}',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey.shade200),

                    // Row 2: Account name
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account name',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            recipient?.name ?? '',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
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
                    // Sender initials avatar
                    CircleAvatar(
                      radius: AppLayout.scaleWidth(context, 20),
                      backgroundColor:
                          const Color(0xFF069494).withValues(alpha: 0.15),
                      child: Text(
                        _initials(senderName),
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF069494),
                        ),
                      ),
                    ),

                    SizedBox(width: AppLayout.scaleWidth(context, 12)),

                    // Sender name + account number + balance
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
                            currencyFormat.format(balance),
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

              // ── Action buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF069494),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF069494),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        TransactionReviewBottomSheet.show(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14),
                        ),
                        backgroundColor: const Color(0xFF069494),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed',
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
            ],
          ),
        ),
      ),
    );
  }
}
