// ============================================================================
// lib/presentation/bill/bill_payment_success.dart
// Generic success screen used after Electricity & Cable TV payments.
// Shows animated checkmark, transaction details, and navigation actions.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/core/app/navigation_helpers.dart';

class BillPaymentSuccessScreen extends StatefulWidget {
  final String title;
  final String providerName;
  final double amount;
  final String transactionId;
  final List<BillSuccessDetail> details;
  final String? prepaidToken;

  const BillPaymentSuccessScreen({
    super.key,
    required this.title,
    required this.providerName,
    required this.amount,
    required this.transactionId,
    required this.details,
    this.prepaidToken,
  });

  @override
  State<BillPaymentSuccessScreen> createState() =>
      _BillPaymentSuccessScreenState();
}

class _BillPaymentSuccessScreenState extends State<BillPaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final result = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(whole[i]);
      count++;
    }
    final formatted = result.toString().split('').reversed.join('');
    return '$formatted.$decimal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App bar ---------------------------------------------
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
                      onTap: () => Navigator.popUntil(
                        context,
                        (r) => r.isFirst,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.close,
                            size: 24, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  Text(
                    widget.title,
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
                  horizontal: AppLayout.scaleWidth(context, 20),
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 32)),

                    // -- Animated success icon ------------------------
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.primaryTeal,
                          size: 52,
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 20)),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          // Provider name
                          Text(
                            widget.providerName,
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 14),
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 6)),

                          // Amount
                          Text(
                            '?${_formatCurrency(widget.amount)}',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 32),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                              fontFamily: 'PolySans',
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 6)),

                          // Status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 14),
                              vertical: AppLayout.scaleHeight(context, 5),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.primaryTeal, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'Payment Successful',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 28)),

                          // -- Prepaid token (electricity only) -------
                          if (widget.prepaidToken != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                  AppLayout.scaleWidth(context, 16)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFFFE082)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Prepaid Token',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 6)),
                                  Text(
                                    widget.prepaidToken!,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 22),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 4)),
                                  Text(
                                    'Enter this token on your meter',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 16)),
                          ],

                          // -- Transaction details card -------------
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                                AppLayout.scaleWidth(context, 16)),
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
                              children: widget.details
                                  .map(
                                    (d) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            d.label,
                                            style: TextStyle(
                                              fontSize: AppLayout.fontSize(
                                                  context, 13),
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              d.value,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: AppLayout.fontSize(
                                                    context, 13),
                                                fontWeight: FontWeight.w500,
                                                color: d.valueColor ??
                                                    const Color(0xFF1A1A2E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 32)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -- Bottom actions --------------------------------------
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 12),
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 24),
              ),
              child: Row(
                children: [
                  // Share receipt
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing receipt...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
                  // Go home
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

class BillSuccessDetail {
  final String label;
  final String value;
  final Color? valueColor;

  const BillSuccessDetail({
    required this.label,
    required this.value,
    this.valueColor,
  });
}
