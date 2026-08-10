// lib/features/passcode/presentation/pages/passcode_setup_screen.dart
//
// Two-stage passcode entry (create, then confirm) built on the existing
// NumericKeypad + PasscodeDotsIndicator widgets.
//
// Pops with the confirmed passcode as a String, so callers await it:
//
//   final passcode = await Navigator.push<String>(context,
//       MaterialPageRoute(builder: (_) => const PasscodeSetupScreen()));
//
// Used by both signup and the forgot-passcode reset so the two cannot
// disagree about format or interaction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/utils/passcode.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/passcode/domain/passcode_state.dart';
import 'package:kudipay/features/passcode/presentation/controllers/passcode_notifier.dart';
import 'package:kudipay/features/passcode/presentation/pages/numeric_keypad.dart';
import 'package:kudipay/features/passcode/presentation/pages/passcode_dots.dart';

/// autoDispose so each visit starts from a clean create stage rather than
/// inheriting a half-finished entry from a previous one.
final passcodeSetupProvider =
    StateNotifierProvider.autoDispose<PasscodeNotifier, PasscodeState>(
  (ref) => PasscodeNotifier(),
);

class PasscodeSetupScreen extends ConsumerStatefulWidget {
  /// Shown above the dots on the create stage.
  final String title;

  /// When supplied, the screen submits the confirmed passcode through this
  /// instead of popping — used by the reset flow, which has to POST it. Throw
  /// from the callback to surface an error and let the user retry.
  final Future<void> Function(String passcode)? onSubmit;

  const PasscodeSetupScreen({
    super.key,
    this.title = 'Create your passcode',
    this.onSubmit,
  });

  @override
  ConsumerState<PasscodeSetupScreen> createState() =>
      _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends ConsumerState<PasscodeSetupScreen> {
  bool _isSubmitting = false;

  Future<void> _submit(String passcode) async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit!(passcode);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Restart entry so the user re-enters both stages after a failure.
      ref.read(passcodeSetupProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passcodeSetupProvider);
    final notifier = ref.read(passcodeSetupProvider.notifier);

    // Hand the confirmed passcode back to the caller.
    ref.listen(passcodeSetupProvider, (previous, next) {
      if (next.isConfirmed && (previous?.isConfirmed != true)) {
        final passcode = notifier.confirmedPasscode;
        if (passcode == null || !mounted) return;
        if (widget.onSubmit != null) {
          _submit(passcode);
        } else {
          Navigator.pop(context, passcode);
        }
      }
    });

    final isConfirmStage = state.stage == PasscodeStage.confirm;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Colors.black, size: AppLayout.scaleWidth(context, 18)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            children: [
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              Text(
                isConfirmStage ? 'Confirm your passcode' : widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 28),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Text(
                isConfirmStage
                    ? 'Enter the same $kPasscodeLength digits again.'
                    : 'Choose $kPasscodeLength digits to sign in with. '
                        'Do not share it with anyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 48)),
              PasscodeDotsIndicator(
                length: kPasscodeLength,
                filledCount: state.enteredPasscode.length,
                showError: state.showError,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              AnimatedOpacity(
                opacity: state.showError ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  state.errorMessage ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IgnorePointer(
                ignoring: _isSubmitting,
                child: Opacity(
                  opacity: _isSubmitting ? 0.5 : 1.0,
                  child: NumericKeypad(
                    onNumberPressed: notifier.addDigit,
                    onBackspacePressed: notifier.removeDigit,
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
            ],
          ),
        ),
      ),
    );
  }
}
