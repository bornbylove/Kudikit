import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/services/transaction_pin_service.dart';


// =============================================================================
// TransactionPinBottomSheet
// =============================================================================
// A reusable bottom sheet that:
//   - Prompts the user for their 4-digit transaction PIN
//   - Verifies it against the securely stored hash
//   - Calls onSuccess() callback when correct (to proceed with payment)
//   - Shows inline error on wrong PIN (max 3 attempts before locking)
//
// Usage:
//   TransactionPinBottomSheet.show(
//     context,
//     title: 'Confirm Transfer',
//     subtitle: 'Enter your transaction PIN to send ₦5,000',
//     onSuccess: () { /* proceed with transfer */ },
//   );
// =============================================================================

class TransactionPinBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const TransactionPinBottomSheet({
    Key? key,
    required this.title,
    this.subtitle,
    required this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onSuccess,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinBottomSheet(
        title: title,
        subtitle: subtitle,
        onSuccess: onSuccess,
        onCancel: onCancel,
      ),
    );
  }

  @override
  ConsumerState<TransactionPinBottomSheet> createState() => _TransactionPinBottomSheetState();
}

class _TransactionPinBottomSheetState extends ConsumerState<TransactionPinBottomSheet> {
  String _pin = '';
  bool _isVerifying = false;
  bool _showError = false;
  String _errorMessage = '';
  int _attemptCount = 0;
  static const int _maxAttempts = 3;
  static const int _pinLength = 4;

  void _onNumberPressed(String number) {
    if (_pin.length >= _pinLength || _isVerifying || _isLocked) return;
    setState(() {
      _pin += number;
      _showError = false;
    });
    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _verifyPin);
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty || _isVerifying) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _showError = false;
    });
  }

  bool get _isLocked => _attemptCount >= _maxAttempts;

  Future<void> _verifyPin() async {
    if (_isLocked) return;
    setState(() => _isVerifying = true);

    try {
      final isValid = await TransactionPinService.instance.verifyTransactionPin(_pin);
      if (!mounted) return;

      if (isValid) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        _attemptCount++;
        final remaining = _maxAttempts - _attemptCount;
        setState(() {
          _isVerifying = false;
          _showError = true;
          _pin = '';
          _errorMessage = _isLocked
              ? 'Too many wrong attempts. Please try again later.'
              : 'Incorrect PIN. $remaining attempt${remaining == 1 ? '' : 's'} remaining.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _showError = true;
          _pin = '';
          _errorMessage = 'Verification failed. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(widget.title,
                    style: TextStyle(fontSize: AppLayout.fontSize(context, 18), fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCancel?.call();
                  },
                ),
              ]),

              if (widget.subtitle != null) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Align(alignment: Alignment.centerLeft,
                  child: Text(widget.subtitle!,
                    style: TextStyle(fontSize: AppLayout.fontSize(context, 13), color: Colors.grey[600]))),
              ],

              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // PIN dots
              _buildPinDots(context),

              SizedBox(height: AppLayout.scaleHeight(context, 10)),

              // Error / loading
              AnimatedOpacity(
                opacity: _showError ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppLayout.fontSize(context, 13), color: Colors.red[600])),
              ),

              if (_isVerifying)
                Padding(
                  padding: EdgeInsets.only(top: AppLayout.scaleHeight(context, 8)),
                  child: const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Color(0xFF069494), strokeWidth: 2.5))),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // Keypad
              Opacity(
                opacity: _isLocked ? 0.4 : 1.0,
                child: IgnorePointer(
                  ignoring: _isLocked || _isVerifying,
                  child: _buildKeypad(context),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 28),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      decoration: BoxDecoration(
        color: _showError ? Colors.red.withValues(alpha: 0.07) : const Color(0xFFDDE8E2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_pinLength, (i) {
          final filled = i < _pin.length;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 8)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (_showError ? Colors.red : const Color(0xFF069494))
                    : Colors.grey[400],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(children: [
      _keypadRow(context, ['1', '2', '3']),
      SizedBox(height: AppLayout.scaleHeight(context, 20)),
      _keypadRow(context, ['4', '5', '6']),
      SizedBox(height: AppLayout.scaleHeight(context, 20)),
      _keypadRow(context, ['7', '8', '9']),
      SizedBox(height: AppLayout.scaleHeight(context, 20)),
      _keypadRow(context, ['', '0', 'delete']),
    ]);
  }

  Widget _keypadRow(BuildContext context, List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return SizedBox(width: AppLayout.scaleWidth(context, 70));
        if (key == 'delete') {
          return _keyBtn(context,
            child: Icon(Icons.backspace_outlined, size: AppLayout.scaleWidth(context, 24), color: Colors.red[400]),
            onTap: _onDeletePressed);
        }
        return _keyBtn(context,
          child: Text(key, style: TextStyle(fontSize: AppLayout.fontSize(context, 28), fontWeight: FontWeight.w400, color: Colors.black87)),
          onTap: () => _onNumberPressed(key));
      }).toList(),
    );
  }

  Widget _keyBtn(BuildContext context, {required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: AppLayout.scaleWidth(context, 70),
        height: AppLayout.scaleHeight(context, 56),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}