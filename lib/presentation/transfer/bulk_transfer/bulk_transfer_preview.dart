import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_otp_sheet.dart';
import 'package:kudipay/provider/transfer/bulk_transfer_provider.dart';

class BulkTransferPreviewScreen extends ConsumerStatefulWidget {
  const BulkTransferPreviewScreen({super.key});

  @override
  ConsumerState<BulkTransferPreviewScreen> createState() =>
      _BulkTransferPreviewScreenState();
}

class _BulkTransferPreviewScreenState
    extends ConsumerState<BulkTransferPreviewScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  bool _isReviewChecked = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkTransferProvider);
    final totalDebit = state.totalDebit;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add manually',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.36,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF069494)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '36%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Amount Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF069494), Color(0xFF2A6B4D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF069494).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount to Debit',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        Text(
                          _currencyFormat.format(totalDebit),
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 32),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 20)),

                  // Summary Card
                  Container(
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
                      children: [
                        _buildSummaryRow(
                          context,
                          'Recipient(s)',
                          '${state.recipientCount}',
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 12)),
                        _buildSummaryRow(
                          context,
                          'Total transfer amount',
                          _currencyFormat.format(state.calculatedTotalAmount),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 12)),
                        _buildSummaryRow(
                          context,
                          'Bank transfer fees',
                          _currencyFormat.format(state.totalBankFees),
                        ),
                        if (state.isScheduled) ...[
                          SizedBox(height: AppLayout.scaleHeight(context, 12)),
                          _buildSummaryRow(
                            context,
                            'Scheduled for',
                            _formatScheduledDateTime(state),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 20)),

                  // Recipients List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recipients (${state.recipientCount})',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.edit,
                          size: AppLayout.scaleWidth(context, 18),
                          color: const Color(0xFF069494),
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: const Color(0xFF069494),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 12)),

                  // Recipients Cards
                  ...state.recipients.map((recipient) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: AppLayout.scaleHeight(context, 12),
                      ),
                      child: _buildRecipientCard(context, recipient),
                    );
                  }).toList(),

                  SizedBox(height: AppLayout.scaleHeight(context, 20)),

                  // Review Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isReviewChecked,
                          onChanged: (value) {
                            setState(() {
                              _isReviewChecked = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF069494),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: Text(
                          'I have reviewed all details and authorize this bulk transfer',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 100)),
                ],
              ),
            ),
          ),

          // Bottom Button
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientCard(
    BuildContext context,
    BulkTransferRecipient recipient,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.name,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  '${recipient.accountType == TransferAccountType.kudikit ? 'Kudikit' : recipient.bankName ?? 'Bank'} • ${recipient.accountNumber}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(recipient.amount ?? 0),
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 15),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final isEnabled = _isReviewChecked;

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 52),
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    _showPinDialog(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEnabled ? const Color(0xFF069494) : const Color(0xFFB8E6CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatScheduledDateTime(BulkTransferState state) {
    if (state.scheduledDate == null) return '';

    final dateFormat = DateFormat('d MMM, yyyy');
    // ignore: unused_local_variable
    final timeFormat = DateFormat('h:mm a');

    final dateStr = dateFormat.format(state.scheduledDate!);
    final timeStr = state.scheduledTime != null
        ? '${state.scheduledTime!.hour.toString().padLeft(2, '0')}:${state.scheduledTime!.minute.toString().padLeft(2, '0')} ${state.scheduledTime!.period == DayPeriod.am ? 'AM' : 'PM'}'
        : '';

    return '$dateStr $timeStr';
  }

  void _showPinDialog(BuildContext context) {
    BulkTransferOtpSheet.show(context);
  }
}
