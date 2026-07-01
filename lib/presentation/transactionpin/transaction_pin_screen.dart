import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/account_ready/account_ready.dart';
import 'package:kudipay/provider/transactionpin/transaction_pin_provider.dart';

class CreateTransactionPinScreen extends ConsumerStatefulWidget {
  /// Set to true when called from Settings (change PIN) to use different nav.
  final bool isChangingPin;

  const CreateTransactionPinScreen({Key? key, this.isChangingPin = false})
      : super(key: key);

  @override
  ConsumerState<CreateTransactionPinScreen> createState() =>
      _CreateTransactionPinScreenState();
}

class _CreateTransactionPinScreenState
    extends ConsumerState<CreateTransactionPinScreen>
    with SingleTickerProviderStateMixin {
  bool _successDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(txPinSetupProvider);
    final notifier = ref.read(txPinSetupProvider.notifier);

    // Trigger success dialog once
    if (state.isComplete && !_successDialogShown) {
      _successDialogShown = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showSuccessOverlay(context, notifier));
    }
    if (!state.isComplete && _successDialogShown) _successDialogShown = false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (state.isConfirmStep) {
          notifier.reset();
          return;
        }
        if (widget.isChangingPin) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ── App Bar ─────────────────────────────────────────────
                  _buildAppBar(context, state, notifier),

                  Expanded(
                    child: Padding(
                      padding: AppLayout.pagePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: AppLayout.scaleHeight(context, 32)),

                          // ── Title (animated cross-fade) ──────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                        position: Tween<Offset>(
                                                begin: const Offset(0, 0.1),
                                                end: Offset.zero)
                                            .animate(animation),
                                        child: child)),
                            child: Column(
                              key: ValueKey<bool>(state.isConfirmStep),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isConfirmStep
                                      ? 'Confirm your passcode'
                                      : 'Create a passcode',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 26),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 10)),
                                Text(
                                  state.isConfirmStep
                                      ? 'Re-enter your PIN to confirm. Don\'t share it with anyone.'
                                      : 'Create a passcode to sign in your account securely.\nPlease, don\'t share your passcode with anyone.',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 48)),

                          // ── PIN dots indicator ───────────────────────────
                          _buildPinDots(context, state),

                          SizedBox(height: AppLayout.scaleHeight(context, 12)),

                          // ── Error message ────────────────────────────────
                          AnimatedOpacity(
                            opacity: state.showError ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              state.isConfirmStep
                                  ? 'PINs don\'t match. Please try again.'
                                  : 'Something went wrong. Try again.',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // ── Numeric keypad ───────────────────────────────
                          IgnorePointer(
                            ignoring: state.isLoading,
                            child: Opacity(
                              opacity: state.isLoading ? 0.5 : 1.0,
                              child: _buildKeypad(context, notifier),
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 40)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Loading overlay ──────────────────────────────────────────
            if (state.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF069494)),
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(BuildContext context, TxPinSetupState state,
      TxPinSetupNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 8),
        vertical: AppLayout.scaleHeight(context, 8),
      ),
      child: Row(
        children: [
          if (state.isConfirmStep || widget.isChangingPin)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black87, size: 20),
              onPressed: () {
                if (state.isConfirmStep) {
                  notifier.reset();
                } else {
                  Navigator.pop(context);
                }
              },
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Step progress indicator
          _buildStepIndicator(context, state),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, TxPinSetupState state) {
    return Row(children: [
      _stepDot(filled: true),
      SizedBox(width: AppLayout.scaleWidth(context, 6)),
      _stepDot(filled: state.isConfirmStep),
    ]);
  }

  Widget _stepDot({required bool filled}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? const Color(0xFF069494) : Colors.grey[300],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PIN dots (pill-shaped container matching the mockup)
  // ---------------------------------------------------------------------------
  Widget _buildPinDots(BuildContext context, TxPinSetupState state) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 32),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      decoration: BoxDecoration(
        color: state.showError
            ? Colors.red.withValues(alpha: 0.08)
            : const Color(0xFFDDE8E2),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final filled = i < state.enteredPin.length;
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 8)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (state.showError ? Colors.red : const Color(0xFF069494))
                    : Colors.grey[400],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Numeric keypad matching the mockup exactly
  // ---------------------------------------------------------------------------
  Widget _buildKeypad(BuildContext context, TxPinSetupNotifier notifier) {
    return Column(children: [
      _keypadRow(context, ['1', '2', '3'], notifier),
      SizedBox(height: AppLayout.scaleHeight(context, 28)),
      _keypadRow(context, ['4', '5', '6'], notifier),
      SizedBox(height: AppLayout.scaleHeight(context, 28)),
      _keypadRow(context, ['7', '8', '9'], notifier),
      SizedBox(height: AppLayout.scaleHeight(context, 28)),
      _keypadRow(context, ['biometric', '0', 'delete'], notifier),
    ]);
  }

  Widget _keypadRow(
      BuildContext context, List<String> keys, TxPinSetupNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'biometric') {
          return _keypadButton(
            context,
            child: Icon(Icons.face_outlined,
                size: AppLayout.scaleWidth(context, 28),
                color: Colors.grey[600]),
            onTap: () {},
          );
        }
        if (key == 'delete') {
          return _keypadButton(
            context,
            child: Icon(Icons.backspace_outlined,
                size: AppLayout.scaleWidth(context, 26),
                color: Colors.red[400]),
            onTap: () => notifier.removeDigit(),
          );
        }
        return _keypadButton(
          context,
          child: Text(key,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 30),
                  fontWeight: FontWeight.w400,
                  color: Colors.black87)),
          onTap: () => notifier.addDigit(key),
        );
      }).toList(),
    );
  }

  Widget _keypadButton(BuildContext context,
      {required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: AppLayout.scaleWidth(context, 72),
        height: AppLayout.scaleWidth(context, 60),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Success overlay
  // ---------------------------------------------------------------------------
  void _showSuccessOverlay(BuildContext context, TxPinSetupNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Animated checkmark
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: const Color(0xFF069494).withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF069494), size: 52),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Transaction PIN Set!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            Text(
                'Your 4-digit transaction PIN has been saved securely. You\'ll use it to authorise all payments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  notifier.reset();
                  if (widget.isChangingPin) {
                    // Settings flow — just pop back to the settings screen.
                    Navigator.pop(context);
                  } else {
                    // Onboarding / KYC flow — push the congratulations screen.
                    // AccountReadyScreen will then clear the entire stack and
                    // push BottomNavBar when the user taps "Proceed to Dashboard".
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountReadyScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    elevation: 0),
                child: Text(widget.isChangingPin ? 'Done' : 'Continue',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
