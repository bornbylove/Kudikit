import 'dart:io';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kudipay/core/utils/responsive.dart';

import 'package:kudipay/features/transfer/domain/entities/bulk_transfer_model.dart';
import 'package:kudipay/features/transfer/presentation/pages/bulk_transfer/bulk_transfer_file_validation_screen.dart';

class BulkTransferUploadFileScreen extends ConsumerStatefulWidget {
  const BulkTransferUploadFileScreen({super.key});

  @override
  ConsumerState<BulkTransferUploadFileScreen> createState() =>
      _BulkTransferUploadFileScreenState();
}

class _BulkTransferUploadFileScreenState
    extends ConsumerState<BulkTransferUploadFileScreen> {
  bool _isUploading = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
                          AppColors.primaryTeal),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // ── Upload tap area ──────────────────────────────────────────────
            GestureDetector(
              onTap: _isUploading ? null : () => _pickFile(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 48),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryTeal,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: AppLayout.scaleWidth(context, 64),
                      height: AppLayout.scaleWidth(context, 64),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.upload_outlined,
                        color: AppColors.primaryTeal,
                        size: AppLayout.scaleWidth(context, 32),
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 16)),
                    Text(
                      _isUploading ? 'Processing...' : 'Tap to upload',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),
                    Text(
                      'Support formats: CSV, Excel (.xlsx, .xls)',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // ── Template info box ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1976D2),
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Text(
                        "Don't have a file ready?",
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  Text(
                    'Download our template and fill in your recipient details',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: const Color(0xFF0D47A1),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  TextButton(
                    onPressed: () => _downloadTemplate(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Download CSV Template here',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: const Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // ── Format requirements ──────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Format Requirements',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _buildRequirement(
                    context,
                    'Include columns: Name, Account Type, Phone/Account, Bank Name, Amount',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildRequirement(
                    context,
                    'Account Type should be "Kudikit" or "Bank"',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildRequirement(
                    context,
                    'Maximum 15 recipients per file',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.primaryTeal,
          size: AppLayout.scaleWidth(context, 18),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File picking
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickFile(BuildContext context) async {
    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        if (!context.mounted) return;
        await _processFile(context, file, fileName);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File processing — parse CSV → validate → navigate
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _processFile(
    BuildContext context,
    File file,
    String fileName,
  ) async {
    // Show loading spinner
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    try {
      final fileContent = await file.readAsString();

      // CsvToListConverter produces List<List<dynamic>>.
      // Use \r\n to handle both Windows and Unix line endings.
      final List<List<dynamic>> allRows = Csv(
        fieldDelimiter: ',',
        dynamicTyping:
            true, // auto-converts numbers, replaces shouldParseNumbers
      ).decode(fileContent.replaceAll('\r\n', '\n'));

      if (allRows.isEmpty) {
        if (context.mounted) _dismissAndSnack(context, 'The file is empty.');
        return;
      }

      // First row = column headers
      final headers = allRows.first.map((e) => e.toString().trim()).toList();

      // Remaining rows = data, each mapped to {header: value}
      final List<Map<String, dynamic>> dataRows = allRows
          .skip(1)
          .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
          .map((row) {
        return {
          for (int i = 0; i < headers.length; i++)
            headers[i]: i < row.length ? row[i] : null,
        };
      }).toList();

      final result = _parseRecipients(dataRows);

      if (context.mounted) Navigator.pop(context); // dismiss spinner

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BulkTransferFileValidationScreen(
              fileName: fileName,
              recipients: result.validRecipients,
              errors: result.errors,
              totalRecipients: dataRows.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _dismissAndSnack(context, 'Error processing file: $e');
      }
    }
  }

  void _dismissAndSnack(BuildContext context, String message) {
    if (mounted) Navigator.pop(context); // dismiss spinner
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Parsing — each row is already Map<String, dynamic> with header keys
  // ─────────────────────────────────────────────────────────────────────────

  ParseResult _parseRecipients(List<Map<String, dynamic>> rows) {
    final List<BulkTransferRecipient> validRecipients = [];
    final List<FileError> errors = [];

    if (rows.isEmpty) {
      errors.add(FileError(row: 0, field: 'File', message: 'File is empty'));
      return ParseResult(validRecipients, errors);
    }

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNumber = i + 2; // +2: row 1 = header, data starts at row 2

      final name = (row['Name'] ?? '').toString().trim();
      final accountType =
          (row['Account Type'] ?? '').toString().trim().toLowerCase();
      final accountNumber = (row['Phone/Account'] ?? '').toString().trim();
      final bankName = (row['Bank Name'] ?? '').toString().trim();
      final rawAmount = row['Amount'];
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '');

      // ── Validate each field ──────────────────────────────────────────────

      if (name.isEmpty) {
        errors.add(FileError(
          row: rowNumber,
          field: 'Name',
          message: 'Name is required',
        ));
      }

      if (accountType != 'kudikit' && accountType != 'bank') {
        errors.add(FileError(
          row: rowNumber,
          field: 'Account Type',
          message: 'Must be "Kudikit" or "Bank"',
        ));
      }

      if (accountNumber.isEmpty) {
        errors.add(FileError(
          row: rowNumber,
          field: 'Phone/Account',
          message: 'Account/Phone is required',
        ));
      }

      if (accountType == 'bank' && bankName.isEmpty) {
        errors.add(FileError(
          row: rowNumber,
          field: 'Bank Name',
          message: 'Bank name is required for bank transfers',
        ));
      }

      if (amount == null || amount <= 0) {
        errors.add(FileError(
          row: rowNumber,
          field: 'Amount',
          message: 'Valid amount is required',
        ));
      }

      // ── Only add the row if it produced no errors ────────────────────────
      final rowHasErrors = errors.any((e) => e.row == rowNumber);
      if (!rowHasErrors) {
        validRecipients.add(
          BulkTransferRecipient(
            id: '${DateTime.now().millisecondsSinceEpoch}$i',
            name: name,
            accountType: accountType == 'kudikit'
                ? TransferAccountType.kudikit
                : TransferAccountType.bank,
            accountNumber: accountNumber,
            phoneNumber: accountType == 'kudikit' ? accountNumber : null,
            bankName: accountType == 'bank' ? bankName : null,
            amount: amount,
            isVerified: true,
          ),
        );
      }
    }

    return ParseResult(validRecipients, errors);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template download (copy to clipboard)
  // ─────────────────────────────────────────────────────────────────────────

  void _downloadTemplate(BuildContext context) {
    const template = 'Name,Account Type,Phone/Account,Bank Name,Amount\n'
        'John Doe,Kudikit,08012345678,,5000\n'
        'Jane Smith,Bank,0123456789,GTBank,10000\n';

    Clipboard.setData(const ClipboardData(text: template));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'CSV template copied to clipboard — paste into Excel or Sheets',
        ),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────────────────────

class ParseResult {
  final List<BulkTransferRecipient> validRecipients;
  final List<FileError> errors;

  const ParseResult(this.validRecipients, this.errors);
}

class FileError {
  final int row;
  final String field;
  final String message;

  const FileError({
    required this.row,
    required this.field,
    required this.message,
  });
}
