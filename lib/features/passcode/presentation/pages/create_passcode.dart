import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/passcode/domain/passcode_state.dart';
import 'package:kudipay/core/navigation/navigation_helpers.dart';
import 'package:kudipay/features/passcode/presentation/pages/numeric_keypad.dart';
import 'package:kudipay/features/passcode/presentation/pages/passcode_dots.dart';
import 'package:kudipay/features/passcode/presentation/controllers/passcode_notifier.dart';

final passcodeProvider =
    StateNotifierProvider<PasscodeNotifier, PasscodeState>((ref) {
  return PasscodeNotifier();
});

class PasscodeCreationScreen extends ConsumerStatefulWidget {
  const PasscodeCreationScreen({super.key});

  @override
  ConsumerState<PasscodeCreationScreen> createState() =>
      _PasscodeCreationScreenState();
}

class _PasscodeCreationScreenState
    extends ConsumerState<PasscodeCreationScreen> {
  bool _dialogShown = false;

  void _showSuccessDialog(BuildContext context, PasscodeNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
        ),
        contentPadding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: BoxDecoration(
                color: Color(0xFF069494).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF069494),
                size: AppLayout.scaleWidth(context, 50),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Text(
              'Passcode created successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 48),
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
                    borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 12),
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue to Home',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
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
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
                children: [
                  SizedBox(height: AppLayout.scaleHeight(context, 40)),
                  // Title
                  Text(
                    'Create your passcode',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  // Subtitle
                  Text(
                    'Create a passcode to sign in your account securely. Please, don\'t share your passcode with anyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 60)),
                  // Passcode Dots Indicator
                  PasscodeDotsIndicator(
                    length: 4,
                    filledCount: passcodeState.enteredPasscode.length,
                    showError: passcodeState.showError,
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  // Error Message
                  AnimatedOpacity(
                    opacity: passcodeState.showError ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      'Passcode doesn\'t match, try again.',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
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
                  SizedBox(height: AppLayout.scaleHeight(context, 40)),
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
