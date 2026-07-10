// ============================================================================
// lib/presentation/bill/bill_transaction_detail.dart
// Generic transaction receipt screen used after any successful bill payment
// (airtime, data, electricity, cable TV).
// Accepts all display data as constructor parameters so it works across
// bill types without being tied to a specific provider.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/core/navigation/navigation_helpers.dart';

class BillTransactionDetail extends StatelessWidget {
  final String title;
  final String transactionId;
  final String billType;
  final String providerName;
  final double amount;
  final DateTime transactionDate;
  final String recipientNumber;
  final String recipientName;
  final String status;
  final Map<String, String> extraDetails;

  const BillTransactionDetail({
    super.key,
    required this.title,
    required this.transactionId,
    required this.billType,
    required this.providerName,
    required this.amount,
    required this.transactionDate,
    required this.recipientNumber,
    required this.recipientName,
    this.status = 'Successful',
    this.extraDetails = const {},
  });

  String _formatCurrency(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    int count = 0;
    for (int i = parts[0].length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(parts[0][i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join('')}.${parts[1]}';
  }

  String _formatDate(DateTime d) {
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
      'Dec'
    ];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m $amPm';
  }

  void _copyTxId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction ID copied'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App bar ------------------------------------------------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 16),
                vertical: AppLayout.scaleHeight(context, 12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left,
                            size: 28, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'PolySans',
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 20)),
                child: Column(
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Success badge ---------------------------------
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryTeal,
                        size: 42,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 12)),

                    Text(
                      status,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),

                    Text(
                      '?${_formatCurrency(amount)}',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 34),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        fontFamily: 'PolySans',
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),

                    Text(
                      '$billType � $providerName',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 24)),

                    // -- Transaction details card ----------------------
                    _DetailCard(
                      children: [
                        _DetailRow(
                            label: 'Recipient',
                            value: recipientName.isNotEmpty
                                ? recipientName
                                : recipientNumber),
                        _DetailRow(
                            label: 'Phone / Account', value: recipientNumber),
                        _DetailRow(label: 'Provider', value: providerName),
                        _DetailRow(
                            label: 'Date', value: _formatDate(transactionDate)),
                        ...extraDetails.entries.map(
                          (e) => _DetailRow(label: e.key, value: e.value),
                        ),
                      ],
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Transaction ID card (tap to copy) -------------
                    GestureDetector(
                      onTap: () => _copyTxId(context),
                      child: Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction ID',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 4)),
                                  Text(
                                    transactionId,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 13),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.copy_outlined,
                                size: 18, color: Color(0xFF9E9E9E)),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 32)),
                  ],
                ),
              ),
            ),

            // -- Bottom action buttons ----------------------------------
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 8),
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyTxId(context),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: Text(
                          'Share',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryTeal,
                          side: const BorderSide(
                              color: AppColors.primaryTeal, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => navigateToMainShell(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Private widgets ----------------------------------------------------------

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    const Divider(height: 16, color: Color(0xFFF0F0F0)),
                ])
            .toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w400,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
