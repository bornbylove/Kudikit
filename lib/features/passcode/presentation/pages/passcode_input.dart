import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/features/passcode/domain/passcode_state.dart';
import 'package:kudipay/core/navigation/navigation_helpers.dart';
import 'package:kudipay/features/passcode/presentation/pages/numeric_keypad.dart';
import 'package:kudipay/features/passcode/presentation/pages/passcode_dots.dart';
import 'package:kudipay/features/passcode/presentation/controllers/passcode_notifier.dart';

final passcodeProvider =
    StateNotifierProvider<PasscodeNotifier, PasscodeState>((ref) {
  return PasscodeNotifier();
});

class PasscodeConfirmationScreen extends ConsumerStatefulWidget {
  const PasscodeConfirmationScreen({super.key});

  @override
  ConsumerState<PasscodeConfirmationScreen> createState() =>
      _PasscodeConfirmationScreenState();
}

class _PasscodeConfirmationScreenState
    extends ConsumerState<PasscodeConfirmationScreen> {
  bool _dialogShown = false;

  void _showSuccessDialog(BuildContext context, PasscodeNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF069494).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF069494),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Success!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Passcode confirmed successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  notifier.reset();
                  // Navigate to home screen
                  navigateToMainShell(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passcodeState = ref.watch(passcodeProvider);
    final passcodeNotifier = ref.read(passcodeProvider.notifier);

    // Show success dialog when confirmed
    if (passcodeState.isConfirmed && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog(context, passcodeNotifier);
      });
    }

    // Reset dialog flag when passcode is reset
    if (!passcodeState.isConfirmed && _dialogShown) {
      _dialogShown = false;
    }

    return Scaffold(
      backgroundColor: Color(0xFFf9f9f9),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    'Confirm your passcode',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Create a passcode to sign in your account securely. Please, don\'t share your passcode with anyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Passcode Dots Indicator
                  PasscodeDotsIndicator(
                    length: 4,
                    filledCount: passcodeState.enteredPasscode.length,
                    showError: passcodeState.showError,
                    // isLoading: passcodeState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  // Error Message
                  AnimatedOpacity(
                    opacity: passcodeState.showError ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Text(
                      'Passcode doesn\'t match, try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Numeric Keypad
                  IgnorePointer(
                    ignoring: passcodeState.isLoading,
                    child: Opacity(
                      opacity: passcodeState.isLoading ? 0.5 : 1.0,
                      child: NumericKeypad(
                        onNumberPressed: (number) {
                          passcodeNotifier.addDigit(number);
                        },
                        onBackspacePressed: () {
                          passcodeNotifier.removeDigit();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (passcodeState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF069494)),
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
