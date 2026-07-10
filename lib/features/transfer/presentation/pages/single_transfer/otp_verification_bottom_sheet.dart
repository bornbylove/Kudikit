import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transfer_success_dialogue.dart';

class OtpVerificationBottomSheet extends ConsumerStatefulWidget {
  final double amount;
  final String maskedPhone;
  final Future<void> Function()? onResend;

  const OtpVerificationBottomSheet({
    super.key,
    required this.amount,
    this.maskedPhone = '*******8790',
    this.onResend,
  });

  static void show(BuildContext context,
      {required double amount,
      String? maskedPhone,
      Future<void> Function()? onResend}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => OtpVerificationBottomSheet(
        amount: amount,
        maskedPhone: maskedPhone ?? '*******8790',
        onResend: onResend,
      ),
    );
  }

  @override
  ConsumerState<OtpVerificationBottomSheet> createState() =>
      _OtpVerificationBottomSheetState();
}

class _OtpVerificationBottomSheetState
    extends ConsumerState<OtpVerificationBottomSheet> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = 240; // 4 minutes
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown() {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  bool _isOtpComplete() {
    return _getOtp().length == 6;
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });

    // Simulate verification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const TransactionSuccessBottomSheet()),
      );
      // Success modal would show here
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _countdown = 240;
    });
    _startCountdown();

    // Resend OTP — calls widget.onResend if provided, otherwise shows snackbar
    if (widget.onResend != null) {
      await widget.onResend!();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.maskedPhone}'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'For money transfer',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: Colors.black54,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Amount
                Text(
                  currencyFormat.format(widget.amount),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 36),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // OTP instruction
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.smartphone,
                      size: AppLayout.scaleWidth(context, 16),
                      color: Colors.black54,
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                    Text(
                      '6 Digit OTP Code',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // OTP input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: AppLayout.scaleWidth(context, 45),
                      height: AppLayout.scaleHeight(context, 50),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 20),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primaryTeal,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                          if (_isOtpComplete()) {
                            _verifyOtp();
                          }
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Countdown and resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'code expires in ${_formatCountdown()}',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: _countdown == 0 ? _resendOtp : null,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: _countdown == 0
                              ? AppColors.primaryTeal
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // OTP sent message
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                    vertical: AppLayout.scaleHeight(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF4CAF50),
                        size: 16,
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 8)),
                      Text(
                        'OTP sent to ${widget.maskedPhone}',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // Having problem link
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.support);
                  },
                  child: Text(
                    'Having problem?',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                if (_isVerifying) ...[
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  const CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                ],

                SizedBox(height: AppLayout.scaleHeight(context, 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
