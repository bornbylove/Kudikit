import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_detail_screen.dart';
import 'package:kudipay/provider/transfer/bulk_transfer_provider.dart';

class BulkTransferSuccessDialog extends ConsumerStatefulWidget {
  const BulkTransferSuccessDialog({super.key});

  @override
  ConsumerState<BulkTransferSuccessDialog> createState() =>
      _BulkTransferSuccessDialogState();
}

class _BulkTransferSuccessDialogState
    extends ConsumerState<BulkTransferSuccessDialog> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  bool _saveAsTemplate = false;
  final TextEditingController _templateNameController = TextEditingController();

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkTransferProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Success Icon
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: const BoxDecoration(
                color: Color(0xFF069494),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: AppLayout.scaleWidth(context, 48),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Amount
            Text(
              '-${_currencyFormat.format(state.totalDebit)}',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 32),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Success Message
            Text(
              'Transfer to ${state.recipientCount} ${state.recipientCount > 1 ? 'RECIPIENTS' : 'RECIPIENT'} is successfully completed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Recipients List (if multiple)
            if (state.recipientCount > 1) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipients (${state.recipientCount})',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 12)),
                    ...state.recipients.map((recipient) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: AppLayout.scaleHeight(context, 8),
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
                                          AppLayout.scaleHeight(context, 2)),
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
                                  _currencyFormat.format(recipient.amount ?? 0),
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 2)),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 11),
                                    color: Color(0xFF069494),
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
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
            ],

            // Save Template Toggle
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Save Template',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Switch(
                    value: _saveAsTemplate,
                    onChanged: (value) {
                      setState(() {
                        _saveAsTemplate = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF389165),
                  ),
                ],
              ),
            ),

            if (_saveAsTemplate) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Template Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title of Template',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  TextField(
                    controller: _templateNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter template name',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: AppLayout.fontSize(context, 15),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F9F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppLayout.scaleHeight(context, 52),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close success dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BulkTransferDetailsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primaryTeal,
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF389165),
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
                        if (_saveAsTemplate) {
                          _saveTemplate();
                        }
                        // Close dialog and navigate to home
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
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

            SizedBox(height: AppLayout.scaleHeight(context, 16)),
          ],
        ),
      ),
    );
  }

  void _saveTemplate() {
    // TODO: Implement template saving
    final templateName = _templateNameController.text.trim();
    if (templateName.isNotEmpty) {
      // Save template logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "$templateName" saved successfully'),
          backgroundColor: const Color(0xFF389165),
        ),
      );
    }
  }
}
