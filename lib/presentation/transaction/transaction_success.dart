import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/wallet/presentation/pages/addmoney/add_money_screen.dart';
import 'package:kudipay/provider/provider.dart';

class TransactionReceiptScreen extends ConsumerWidget {
  const TransactionReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardTopUpState = ref.watch(cardTopUpProvider);
    final receipt = cardTopUpState.receipt;

    if (receipt == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F5),
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('No receipt available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, receipt),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF9F9F9),
      elevation: 0,
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
      actions: [
        IconButton(
          icon: Icon(
            Icons.headset_mic_outlined,
            color: const Color(0xFF069494),
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () {
            // Contact support
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, receipt) {
    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // Success Card
          _buildSuccessCard(context, receipt),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // Transaction Details
          _buildTransactionDetails(context, receipt),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // Action Buttons
          _buildActionButtons(context),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context, receipt) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        children: [
          // Bank Icon
          Container(
            width: AppLayout.scaleWidth(context, 60),
            height: AppLayout.scaleWidth(context, 60),
            decoration: const BoxDecoration(
              color: Color(0xFFdbf0e2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              color: const Color(0xFF069494).withValues(alpha: 0.35),
              size: AppLayout.scaleWidth(context, 15),
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Transaction Type
          Text(
            receipt.transactionType,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 8)),

          // Amount
          Text(
            '?${_formatAmount(receipt.amount)}',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 32),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 12)),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 12),
              vertical: AppLayout.scaleHeight(context, 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF15b47b),
                  size: AppLayout.scaleWidth(context, 16),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 6)),
                Text(
                  receipt.status,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15B47B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context, receipt) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 20)),
          _buildDetailRow(
            context,
            'Recipient Details',
            receipt.payingBank,
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            'Transaction No.',
            receipt.transactionNumber,
            isLongText: true,
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            'Payment Type',
            receipt.creditedTo,
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            'Transaction Date',
            _formatDate(receipt.transactionDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isLongText = false,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 12)),
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
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: isLongText ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Colors.grey[200],
      height: 1,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Share receipt
            },
            icon: Icon(
              Icons.share_outlined,
              size: AppLayout.scaleWidth(context, 20),
            ),
            label: Text(
              'Share',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF9F9F9),
              side: const BorderSide(color: Color(0xFF069494), width: 1),
              backgroundColor: const Color(0xFFf9f9f9),
              minimumSize: Size(
                0,
                AppLayout.scaleHeight(context, 50),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 12))),
            ),
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 16)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Download receipt
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMoneyScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.download_outlined,
              size: AppLayout.scaleWidth(context, 20),
            ),
            label: Text(
              'Download',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF069494),
              foregroundColor: Colors.white,
              minimumSize: Size(
                0,
                AppLayout.scaleHeight(context, 50),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd\'th\', yyyy HH:mm:ss').format(date);
  }
}
