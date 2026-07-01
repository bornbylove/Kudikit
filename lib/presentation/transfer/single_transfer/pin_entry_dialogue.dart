import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transfer_success_dialogue.dart';
import 'package:kudipay/provider/provider.dart';

// ── Processing Payment Screen ───────────────────────────────────────────────
// Shown as a full screen while the transfer is being processed.
class ProcessingPaymentScreen extends StatelessWidget {
  const ProcessingPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF069494)),
                backgroundColor: Color(0xFFD0EDED),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Processing payment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PIN Entry Bottom Sheet ──────────────────────────────────────────────────
class PinEntryBottomSheet extends ConsumerStatefulWidget {
  const PinEntryBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PinEntryBottomSheet(),
    );
  }

  @override
  ConsumerState<PinEntryBottomSheet> createState() =>
      _PinEntryBottomSheetState();
}

class _PinEntryBottomSheetState extends ConsumerState<PinEntryBottomSheet> {
  String _pin = '';
  final int _pinLength = 6;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      // Auto-submit when PIN is complete
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _submitPin();
        });
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _submitPin() async {
    if (!mounted) return;

    // Close the PIN bottom sheet first
    Navigator.pop(context);

    // Navigate to the processing screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProcessingPaymentScreen(),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    // Process the transfer in the background
    await ref.read(p2pTransferProvider.notifier).processTransfer(_pin);

    if (mounted) {
      // Replace the processing screen with the success screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const TransactionSuccessBottomSheet(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

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
            AppLayout.scaleHeight(context, 16),
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ─────────────────────────────────────────
              Center(
                child: Container(
                  width: AppLayout.scaleWidth(context, 40),
                  height: AppLayout.scaleHeight(context, 4),
                  margin: EdgeInsets.only(
                      bottom: AppLayout.scaleHeight(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enter Transaction PIN',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 36)),

              // ── PIN dots ──────────────────────────────────────────
              _buildPinDots(context),

              SizedBox(height: AppLayout.scaleHeight(context, 40)),

              // ── Numeric keypad ────────────────────────────────────
              _buildKeypad(context),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 8),
          ),
          width: AppLayout.scaleWidth(context, 14),
          height: AppLayout.scaleWidth(context, 14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF069494) : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      children: [
        _buildKeypadRow(context, ['1', '2', '3']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['4', '5', '6']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['7', '8', '9']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['', '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return SizedBox(width: AppLayout.scaleWidth(context, 72));
        }

        if (number == 'delete') {
          return _buildKeypadButton(
            context,
            child: Icon(
              Icons.backspace_outlined,
              color: Colors.black87,
              size: AppLayout.scaleWidth(context, 22),
            ),
            onPressed: _onDeletePressed,
          );
        }

        return _buildKeypadButton(
          context,
          child: Text(
            number,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 22),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          onPressed: () => _onNumberPressed(number),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
    BuildContext context, {
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: AppLayout.scaleWidth(context, 72),
        height: AppLayout.scaleWidth(context, 72),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
