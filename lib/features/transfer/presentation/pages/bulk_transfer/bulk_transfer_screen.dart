import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_template_screen.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_upload_file_screen.dart';
import 'package:kudipay/presentation/transfer/single_transfer/add_recipient_screen.dart';

class BulkTransferScreen extends ConsumerWidget {
  const BulkTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Padding(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // Header text
              Text(
                'How would you like to add recipients?',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 5)),

              Text(
                'Choose one method to get started. You can combine methods later.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 22)),

              // Add Manually Option
              _buildMethodOption(
                context: context,
                icon: Icons.person_add_outlined,
                iconColor: const Color(0xFF069494),
                iconBgColor: const Color(0xFFE8F5E9),
                title: 'Add manually',
                subtitle: 'Add recipient one by one by adding their details',
                badgeText: 'Most flexible',
                badgeColor: const Color(0xFF069494),
                recommendedText: 'Best for 1-5 recipients',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRecipientsManuallyScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 14)),

              // Upload File Option
              _buildMethodOption(
                context: context,
                icon: Icons.upload_file_outlined,
                iconColor: const Color(0xFF5E35B1),
                iconBgColor: const Color(0xFFF3E5F5),
                title: 'Upload File',
                subtitle: 'Add recipient one by one by adding their details',
                badgeText: 'Fastest',
                badgeColor: const Color(0xFF7E57C2),
                recommendedText: 'Best for 5+ recipients',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BulkTransferUploadFileScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 14)),

              // Use Template Option
              _buildMethodOption(
                context: context,
                icon: Icons.bookmark_outline,
                iconColor: const Color(0xFFE91E63),
                iconBgColor: const Color(0xFFFCE4EC),
                title: 'Use Template',
                subtitle: 'Reuse saved recipients group',
                badgeText: 'Recurring',
                badgeColor: const Color(0xFFEC407A),
                recommendedText: '2 templates saved',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BulkTransferTemplatesScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 22)),

              // Info box
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFE082),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFF9A825),
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: Text(
                        'You can add up to 15 recipients per bulk transfer. Transfers to more than 5 bank accounts qualify for bulk discounts.',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: const Color(0xFF6D4C00),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String recommendedText,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: AppLayout.scaleWidth(context, 48),
                      height: AppLayout.scaleWidth(context, 48),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: AppLayout.scaleWidth(context, 24),
                      ),
                    ),

                    const Spacer(),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 11),
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 6)),

                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 12)),

                // Recommended text
                Text(
                  recommendedText,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
