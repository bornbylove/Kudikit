import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/provider/provider.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(p2pTransferProvider);
    final result = state.transactionResult!;
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 24),
          ),
          child: Column(
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Main card
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
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
                        color: AppColors.primaryTeal,
                        size: AppLayout.scaleWidth(context, 32),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // Transaction title
                    Text(
                      'Add Money - Bank Card',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // Amount
                    Text(
                      currencyFormat.format(result.amount),
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 36),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 8)),

                    // Status
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 12),
                        vertical: AppLayout.scaleHeight(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primaryTeal,
                            size: AppLayout.scaleWidth(context, 16),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 6)),
                          Text(
                            'successful',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 32)),

                    // Transaction details header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // Details list
                    _buildDetailRow(
                      context,
                      'Transaction Type',
                      result.transactionType,
                    ),
                    _buildDivider(context),
                    _buildDetailRow(
                      context,
                      'Fees',
                      currencyFormat.format(result.fee),
                    ),
                    _buildDivider(context),
                    _buildDetailRow(
                      context,
                      'Paying Bank',
                      '${result.payingBank}\n(${result.payingBankAccount})',
                    ),
                    _buildDivider(context),
                    _buildDetailRow(
                      context,
                      'Credited to',
                      result.creditedTo,
                    ),
                    _buildDivider(context),
                    _buildDetailRow(
                      context,
                      'Transaction No.',
                      result.transactionId,
                      isSelectable: true,
                    ),
                    _buildDivider(context),
                    _buildDetailRow(
                      context,
                      'Transaction Date',
                      dateFormat.format(result.transactionDate),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _shareTransaction(context, result),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 16),
                        ),
                        side: const BorderSide(
                          color: AppColors.primaryTeal,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Share',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _downloadReceipt(context, result),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 16),
                        ),
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
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
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 40)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transaction Details',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.support);
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isSelectable = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),
          Expanded(
            flex: 3,
            child: isSelectable
                ? SelectableText(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
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
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Colors.grey[200],
      thickness: 1,
      height: 1,
    );
  }

  void _shareTransaction(BuildContext context, TransactionResult result) {
    // Copy transaction summary to clipboard — no external package needed.
    final fmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final summary = 'KudiPay Receipt\n'
        'Type: ${result.transactionType}\n'
        'Amount: ${fmt.format(result.amount)}\n'
        'To: ${result.creditedTo}\n'
        'Date: ${DateFormat('MMM d, yyyy h:mm a').format(result.transactionDate)}\n'
        'Ref: ${result.transactionId}';
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt details copied to clipboard'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadReceipt(BuildContext context, TransactionResult result) {
    // Copy transaction ID to clipboard as a download reference.
    Clipboard.setData(ClipboardData(text: result.transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Transaction ID copied — use it to request a receipt'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
