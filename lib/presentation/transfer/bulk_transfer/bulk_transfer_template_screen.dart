import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:kudipay/presentation/transfer/single_transfer/add_recipient_screen.dart';
import 'package:kudipay/provider/transfer/bulk_transfer_provider.dart';

class BulkTransferTemplatesScreen extends ConsumerWidget {
  const BulkTransferTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(bulkTransferTemplatesProvider);

    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 0,
    );

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
          'Bulk Transfer',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Title
            Text(
              'Your Saved Templates',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Subtitle
            Text(
              'Choose a template to quickly send recurring payments',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Templates List
            templatesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(color: Color(0xFF069494)),
                ),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Text(
                    'Could not load templates. Pull to refresh.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ),
              data: (templates) => templates.isEmpty
                  ? _buildEmptyState(context)
                  : Column(
                      children: templates.map((template) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: AppLayout.scaleHeight(context, 16),
                          ),
                          child: _TemplateCard(
                            template: template,
                            currencyFormat: currencyFormat,
                            onUseTemplate: () {
                              ref
                                  .read(bulkTransferProvider.notifier)
                                  .loadFromTemplate(template);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddRecipientsManuallyScreen(),
                                ),
                              );
                            },
                            onDelete: () {
                              _showDeleteDialog(context, template);
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 80),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bookmark_border,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.grey[300],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'No saved templates',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Text(
              'Templates you save will appear here',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BulkTransferTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement template deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "${template.name}" deleted'),
                  backgroundColor: const Color(0xFF069494),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final BulkTransferTemplate template;
  final NumberFormat currencyFormat;
  final VoidCallback onUseTemplate;
  final VoidCallback onDelete;

  const _TemplateCard({
    Key? key,
    required this.template,
    required this.currencyFormat,
    required this.onUseTemplate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalAmount = template.recipients.fold<double>(
      0.0,
      (sum, r) => sum + (r.amount ?? 0),
    );

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
          // Header
          Row(
            children: [
              // Icon
              Container(
                width: AppLayout.scaleWidth(context, 40),
                height: AppLayout.scaleWidth(context, 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bookmark,
                  color: const Color(0xFFE91E63),
                  size: AppLayout.scaleWidth(context, 20),
                ),
              ),

              SizedBox(width: AppLayout.scaleWidth(context, 11)),

              // Template Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: AppLayout.scaleWidth(context, 12),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 4)),
                        Text(
                          '${template.recipients.length} recipients',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 11),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 10)),
                        Icon(
                          Icons.access_time,
                          size: AppLayout.scaleWidth(context, 12),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: AppLayout.scaleWidth(context, 4)),
                        Text(
                          'Last used ${_formatDate(template.createdAt)}',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 11),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: AppLayout.scaleWidth(context, 20),
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total amount',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                currencyFormat.format(totalAmount),
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Use Template Button
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: onUseTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Use Template',
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }
}
