import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';

import 'package:kudipay/provider/transfer/bulk_transfer_provider.dart';

class BulkTransferDetailsScreen extends ConsumerWidget {
  const BulkTransferDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bulkTransferProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 2,
    );
    final DateFormat dateFormat = DateFormat('MMM d, yyyy HH:mm:ss');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.support);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Success Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: AppLayout.scaleWidth(context, 64),
                    height: AppLayout.scaleWidth(context, 64),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: const Color(0xFF069494),
                      size: AppLayout.scaleWidth(context, 32),
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Description
                  Text(
                    'Successfully transferred to ${state.recipientCount} recipient${state.recipientCount > 1 ? 's' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 12)),

                  // Amount
                  Text(
                    currencyFormat.format(state.totalDebit),
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 32),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 12)),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFF069494),
                          size: AppLayout.scaleWidth(context, 16),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 6)),
                        Text(
                          'successful',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 13),
                            color: const Color(0xFF069494),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Batch Details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Details',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _buildDetailRow(
                    context,
                    'Transaction No.',
                    '213546364738B2937447493',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildDetailRow(
                    context,
                    'Transaction Date',
                    dateFormat.format(DateTime.now()),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildDetailRow(
                    context,
                    'Recipients',
                    '${state.recipientCount}',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildDetailRow(
                    context,
                    'Status',
                    'Successful',
                    valueColor: const Color(0xFF069494),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Successful Transfers
            if (state.recipients.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successful Transfers (${state.recipientCount})',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 16)),
                    ...state.recipients.map((recipient) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: AppLayout.scaleHeight(context, 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipient.name,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 14),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 4)),
                                  Text(
                                    '${recipient.accountType.toString().split('.').last} • ${recipient.accountNumber}',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(recipient.amount ?? 0),
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 4)),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 11),
                                    color: const Color(0xFF069494),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppLayout.scaleHeight(context, 52),
                    child: OutlinedButton(
                      onPressed: () {
                        _shareReceipt(context, ref);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF069494),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        'Share',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF069494),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 12)),
                Expanded(
                  child: SizedBox(
                    height: AppLayout.scaleHeight(context, 52),
                    child: ElevatedButton(
                      onPressed: () {
                        _downloadReceipt(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF069494),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Download',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[500],
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 16)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _shareReceipt(BuildContext context, WidgetRef ref) {
    final state = ref.read(bulkTransferProvider);
    final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final summary = 'KudiPay Bulk Transfer\n'
        'Recipients: ${state.recipientCount}\n'
        'Total: ${fmt.format(state.totalDebit)}\n'
        'Status: Completed';
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transfer summary copied to clipboard'),
        backgroundColor: const Color(0xFF069494),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadReceipt(BuildContext context, WidgetRef ref) {
    final state = ref.read(bulkTransferProvider);
    final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final receipt = 'KudiPay Bulk Transfer Receipt\n'
        'Recipients: ${state.recipientCount}\n'
        'Total Debited: ${fmt.format(state.totalDebit)}\n'
        '---\n'
        '${state.recipients.map((r) => '${r.name}: ${fmt.format(r.amount)}').join('\n')}';
    Clipboard.setData(ClipboardData(text: receipt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt copied to clipboard'),
        backgroundColor: const Color(0xFF069494),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
