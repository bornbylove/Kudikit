import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/features/transfer/presentation/pages/bulk_transfer/bulk_transfer_success.dart';

class BulkTransferPinDialog extends ConsumerStatefulWidget {
  const BulkTransferPinDialog({super.key});

  @override
  ConsumerState<BulkTransferPinDialog> createState() =>
      _BulkTransferPinDialogState();
}

class _BulkTransferPinDialogState extends ConsumerState<BulkTransferPinDialog> {
  String _pin = '';
  bool _isLoading = false;
  final int _pinLength = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Title and close button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Text(
                    'Enter Transaction PIN',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: AppLayout.scaleWidth(context, 24),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 6),
                  ),
                  width: AppLayout.scaleWidth(context, 12),
                  height: AppLayout.scaleWidth(context, 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? const Color(0xFF069494)
                        : const Color(0xFFE0E0E0),
                  ),
                );
              }),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Loading indicator
            if (_isLoading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF069494),
                ),
              )
            else
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Numeric keypad
            _buildNumericKeypad(context),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 40),
      ),
      child: Column(
        children: [
          _buildKeypadRow(context, ['1', '2', '3']),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildKeypadRow(context, ['4', '5', '6']),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildKeypadRow(context, ['7', '8', '9']),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildKeypadRow(context, ['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return SizedBox(
            width: AppLayout.scaleWidth(context, 70),
            height: AppLayout.scaleWidth(context, 70),
          );
        }

        if (number == 'delete') {
          return GestureDetector(
            onTap: _isLoading ? null : _deletePin,
            child: Container(
              width: AppLayout.scaleWidth(context, 70),
              height: AppLayout.scaleWidth(context, 70),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back,
                color: Colors.red[400],
                size: AppLayout.scaleWidth(context, 28),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: _isLoading ? null : () => _addPin(number),
          child: Container(
            width: AppLayout.scaleWidth(context, 70),
            height: AppLayout.scaleWidth(context, 70),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _addPin(String digit) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += digit);
      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _deletePin() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length != _pinLength) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(bulkTransferProvider.notifier)
          .executeBulkTransfer(pin: _pin);

      if (mounted) Navigator.pop(context);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showSuccessDialog();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => const BulkTransferSuccessDialog(),
    );
  }
}
