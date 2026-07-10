import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_preview.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_upload_file_screen.dart';
import 'package:kudipay/provider/transfer/bulk_transfer_provider.dart';

class BulkTransferFileValidationScreen extends ConsumerStatefulWidget {
  final String fileName;
  final List<BulkTransferRecipient> recipients;
  final List<FileError> errors;
  final int totalRecipients;

  const BulkTransferFileValidationScreen({
    super.key,
    required this.fileName,
    required this.recipients,
    required this.errors,
    required this.totalRecipients,
  });

  @override
  ConsumerState<BulkTransferFileValidationScreen> createState() =>
      _BulkTransferFileValidationScreenState();
}

class _BulkTransferFileValidationScreenState
    extends ConsumerState<BulkTransferFileValidationScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  late List<BulkTransferRecipient> _editableRecipients;
  late Map<String, List<String>> _recipientErrors;

  @override
  void initState() {
    super.initState();
    _editableRecipients = List.from(widget.recipients);
    _recipientErrors = _mapErrors();
  }

  Map<String, List<String>> _mapErrors() {
    Map<String, List<String>> errorMap = {};
    for (var error in widget.errors) {
      final key = 'recipient_${error.row - 1}';
      if (!errorMap.containsKey(key)) {
        errorMap[key] = [];
      }
      errorMap[key]!.add('${error.field}: ${error.message}');
    }
    return errorMap;
  }

  int get validCount => _editableRecipients.where((r) {
        final key = 'recipient_${_editableRecipients.indexOf(r)}';
        return !_recipientErrors.containsKey(key) ||
            _recipientErrors[key]!.isEmpty;
      }).length;

  int get errorCount => widget.errors.length;

  double get totalAmount => _editableRecipients.fold(
        0.0,
        (sum, r) => sum + (r.amount ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final hasErrors = widget.errors.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload File',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '36%',
                  style: TextStyle(
                    color: Color(0xFF069494),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // File Info Header
                  Container(
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          width: AppLayout.scaleWidth(context, 48),
                          height: AppLayout.scaleWidth(context, 48),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.insert_drive_file_outlined,
                            color: const Color(0xFF069494),
                            size: AppLayout.scaleWidth(context, 24),
                          ),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.fileName,
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 15),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                  height: AppLayout.scaleHeight(context, 4)),
                              Text(
                                '${widget.totalRecipients} recipients found',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 13),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Change file',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 14),
                              color: const Color(0xFF069494),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Banner (if errors exist)
                  if (hasErrors)
                    Container(
                      margin: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF5350)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: const Color(0xFFD32F2F),
                            size: AppLayout.scaleWidth(context, 24),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$errorCount errors found',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 15),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 4)),
                                Text(
                                  '• Fix bank name for bank transfers\n• Row ${widget.errors.first.row} is required',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 13),
                                    color: const Color(0xFFC62828),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Total Amount Card
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                    ),
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
                          _currencyFormat.format(totalAmount),
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 32),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Summary Card
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                    ),
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          'Recipient(s)',
                          '${_editableRecipients.length}',
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        _buildSummaryRow(
                          context,
                          'Total transfer amount',
                          _currencyFormat.format(totalAmount),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        _buildSummaryRow(
                          context,
                          'Bank transfer fees',
                          '₦10.00',
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        _buildSummaryRow(
                          context,
                          'Bank transfer fees',
                          _currencyFormat.format(totalAmount + 10),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Recipients List
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recipients (${_editableRecipients.length})',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 12)),

                  // Recipient Cards
                  ...List.generate(_editableRecipients.length, (index) {
                    final recipient = _editableRecipients[index];
                    final key = 'recipient_$index';
                    final hasError = _recipientErrors.containsKey(key) &&
                        _recipientErrors[key]!.isNotEmpty;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: AppLayout.scaleWidth(context, 16),
                        right: AppLayout.scaleWidth(context, 16),
                        bottom: AppLayout.scaleHeight(context, 12),
                      ),
                      child: _RecipientValidationCard(
                        recipient: recipient,
                        recipientNumber: index + 1,
                        hasError: hasError,
                        errors: _recipientErrors[key] ?? [],
                        currencyFormat: _currencyFormat,
                      ),
                    );
                  }),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Validation Summary
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                    ),
                    padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validation Summary',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 12)),
                        Row(
                          children: [
                            Text(
                              'Valid recipients',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 14),
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$validCount/${_editableRecipients.length}',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF069494),
                              ),
                            ),
                          ],
                        ),
                        if (hasErrors) ...[
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),
                          Row(
                            children: [
                              Text(
                                'Errors to fix',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$errorCount',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF5350),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 100)),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          _buildBottomButtons(context, hasErrors),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
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
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, bool hasErrors) {
    final isEnabled = !hasErrors && validCount > 0;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 52),
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        _continueToPreview();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? const Color(0xFF069494)
                      : const Color(0xFFB8E6CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue with $validCount recipient${validCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 52),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
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
                  'Cancel',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF069494),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToPreview() {
    // Add valid recipients to provider
    final validRecipients = _editableRecipients.where((r) {
      final index = _editableRecipients.indexOf(r);
      final key = 'recipient_$index';
      return !_recipientErrors.containsKey(key) ||
          _recipientErrors[key]!.isEmpty;
    }).toList();

    // Clear existing recipients and add new ones
    ref.read(bulkTransferProvider.notifier).clearRecipients();
    for (var recipient in validRecipients) {
      ref.read(bulkTransferProvider.notifier).addRecipient(recipient);
    }

    // Navigate to preview
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BulkTransferPreviewScreen(),
      ),
    );
  }
}

class _RecipientValidationCard extends StatelessWidget {
  final BulkTransferRecipient recipient;
  final int recipientNumber;
  final bool hasError;
  final List<String> errors;
  final NumberFormat currencyFormat;

  const _RecipientValidationCard({
    required this.recipient,
    required this.recipientNumber,
    required this.hasError,
    required this.errors,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? const Color(0xFFEF5350) : const Color(0xFF069494),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 32),
                height: AppLayout.scaleWidth(context, 32),
                decoration: BoxDecoration(
                  color: hasError
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF069494),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    hasError ? Icons.close : Icons.check,
                    color: Colors.white,
                    size: AppLayout.scaleWidth(context, 18),
                  ),
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: Text(
                  hasError
                      ? 'Recipient $recipientNumber - Fix errors below'
                      : 'Recipient $recipientNumber',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: hasError ? const Color(0xFFD32F2F) : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 10),
                  vertical: AppLayout.scaleHeight(context, 4),
                ),
                decoration: BoxDecoration(
                  color: recipient.accountType == TransferAccountType.kudikit
                      ? const Color(0xFF069494).withValues(alpha: 0.2)
                      : const Color(0xFF2196F3).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recipient.accountType == TransferAccountType.kudikit
                      ? 'Kudikit'
                      : 'Bank',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 11),
                    fontWeight: FontWeight.w600,
                    color: recipient.accountType == TransferAccountType.kudikit
                        ? const Color(0xFF069494)
                        : const Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Details
          _buildDetailRow(context, 'Name', recipient.name,
              hasError: errors.any((e) => e.contains('Name'))),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          _buildDetailRow(
            context,
            recipient.accountType == TransferAccountType.kudikit
                ? 'Phone Number'
                : 'Account Number',
            recipient.accountNumber,
          ),
          if (recipient.accountType == TransferAccountType.bank) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _buildDetailRow(
              context,
              'Bank Name',
              recipient.bankName ?? 'Not specified',
              hasError: errors.any((e) => e.contains('Bank')),
            ),
          ],
          if (recipient.narration != null &&
              recipient.narration!.isNotEmpty) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _buildDetailRow(
                context, 'Narration (optional)', recipient.narration!),
          ],

          // Error Messages
          if (hasError && errors.isNotEmpty) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.map((error) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: AppLayout.scaleHeight(context, 4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: const Color(0xFFD32F2F),
                          size: AppLayout.scaleWidth(context, 16),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 8)),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Amount
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(recipient.amount ?? 0),
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: hasError ? const Color(0xFFD32F2F) : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 12),
            color: hasError ? const Color(0xFFD32F2F) : Colors.grey[700],
            fontWeight: hasError ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 4)),
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: hasError ? const Color(0xFFD32F2F) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
