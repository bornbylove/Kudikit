import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_success.dart';
import 'package:kudipay/provider/provider.dart';

/// Masks a phone number showing only the last 4 digits.
/// e.g. "08124608695" → "*******8695"
String _maskPhone(String phone) {
  if (phone.length <= 4) return phone;
  return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
}

/// OTP Verification bottom sheet shown at the end of the bulk transfer flow.
/// The OTP is sent to the phone number on the user's account (from UserModel).
class BulkTransferOtpSheet extends ConsumerStatefulWidget {
  const BulkTransferOtpSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BulkTransferOtpSheet(),
    );
  }

  @override
  ConsumerState<BulkTransferOtpSheet> createState() =>
      _BulkTransferOtpSheetState();
}

class _BulkTransferOtpSheetState extends ConsumerState<BulkTransferOtpSheet> {
  static const int _otpLength = 6;
  static const int _countdownSeconds = 4 * 60; // 4 minutes

  /// Reads the phone number from UserModel and masks it for display.
  String get _maskedPhone {
    final user = ref.read(currentUserProvider);
    final phone = user?.phoneNumber ?? '';
    return phone.isNotEmpty ? _maskPhone(phone) : '*******0000';
  }

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  late int _secondsRemaining;
  Timer? _timer;
  bool _hasError = false;
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _countdownSeconds;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(1, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _canResend => _secondsRemaining <= 0;

  // ── OTP input handling ─────────────────────────────────────────────────

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (_hasError) setState(() => _hasError = false);

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  void _resendOtp() {
    if (!_canResend) return;
    // TODO: call API to resend OTP
    setState(() {
      _hasError = false;
      _errorMessage = '';
      for (final c in _controllers) {
        c.clear();
      }
    });
    _startTimer();
    _focusNodes[0].requestFocus();
  }

  // ── Verification ───────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _currentOtp;
    if (otp.length < _otpLength) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      await ref
          .read(bulkTransferProvider.notifier)
          .executeBulkTransfer(pin: otp);
      if (mounted) {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200));
        _showSuccess();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isVerifying = false;
          _errorMessage = 'Verification failed. Try again.';
        });
      }
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const BulkTransferSuccessDialog(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 20),
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ───────────────────────────────────────
              Center(
                child: Container(
                  width: AppLayout.scaleWidth(context, 40),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Header ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'For money transfer',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: AppLayout.scaleWidth(context, 28),
                      height: AppLayout.scaleWidth(context, 28),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 12)),

              // ── Amount ──────────────────────────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final totalDebit = ref.watch(bulkTransferProvider).totalDebit;
                  final formatted = NumberFormat.currency(
                    symbol: '₦',
                    decimalDigits: 2,
                  ).format(totalDebit);
                  return Text(
                    formatted,
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 32),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF069494),
                    ),
                  );
                },
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── OTP label ───────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: AppLayout.scaleWidth(context, 16),
                    color: Colors.black54,
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 6)),
                  Text(
                    '6 Digit OTP Code',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 14)),

              // ── OTP Input Boxes ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (index) {
                  return _OtpBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    hasError: _hasError,
                    onChanged: (val) => _onDigitChanged(index, val),
                    onKeyEvent: (event) => _onKeyEvent(index, event),
                  );
                }),
              ),

              // ── Error message ────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _hasError
                    ? Padding(
                        padding: EdgeInsets.only(
                            top: AppLayout.scaleHeight(context, 8)),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            fontFamily: 'PolySans',
                            fontSize: AppLayout.fontSize(context, 13),
                            color: Colors.red,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 12)),

              // ── Timer + Resend ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _canResend ? '' : 'code expires in $_formattedTime',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black45,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canResend ? _resendOtp : null,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF069494),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── OTP sent banner ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 20),
                  vertical: AppLayout.scaleHeight(context, 14),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'OTP sent to $_maskedPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 13),
                    color: const Color(0xFF069494),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // ── Having problem? ──────────────────────────────────
              GestureDetector(
                onTap: () {
                  // TODO: navigate to support
                },
                child: Text(
                  'Having problem?',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 13),
                    color: const Color(0xFF069494),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              // ── Loading indicator ────────────────────────────────
              if (_isVerifying) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 16)),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF069494),
                  ),
                ),
              ],

              SizedBox(height: AppLayout.scaleHeight(context, 8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual OTP input box ───────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: AppLayout.scaleWidth(context, 46),
        height: AppLayout.scaleWidth(context, 52),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Colors.black87,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFF069494),
                width: 1.5,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
