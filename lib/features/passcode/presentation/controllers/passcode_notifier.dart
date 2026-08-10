// lib/features/passcode/presentation/controllers/passcode_notifier.dart
//
// Drives the two-stage passcode setup: enter it once, then re-enter to
// confirm. Length comes from kPasscodeLength so the digit count is defined in
// one place.
//
// This previously compared every entry against a hardcoded '1234' with a fake
// 800ms delay — a stub, not a working create flow.

import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/utils/passcode.dart';
import 'package:kudipay/features/passcode/domain/passcode_state.dart';

class PasscodeNotifier extends StateNotifier<PasscodeState> {
  PasscodeNotifier() : super(const PasscodeState());

  void addDigit(String digit) {
    if (state.enteredPasscode.length >= kPasscodeLength) return;

    final next = state.enteredPasscode + digit;
    state = state.copyWith(
      enteredPasscode: next,
      showError: false,
      errorMessage: null,
    );

    if (next.length == kPasscodeLength) _onStageComplete(next);
  }

  void removeDigit() {
    if (state.enteredPasscode.isEmpty) return;
    state = state.copyWith(
      enteredPasscode:
          state.enteredPasscode.substring(0, state.enteredPasscode.length - 1),
      showError: false,
      errorMessage: null,
    );
  }

  void _onStageComplete(String entered) {
    if (state.stage == PasscodeStage.create) {
      // Guards against a non-digit ever reaching here via a different keypad.
      final error = passcodeError(entered);
      if (error != null) {
        state = state.copyWith(
          enteredPasscode: '',
          showError: true,
          errorMessage: error,
        );
        return;
      }

      state = state.copyWith(
        originalPasscode: entered,
        enteredPasscode: '',
        stage: PasscodeStage.confirm,
      );
      return;
    }

    // Confirm stage.
    if (entered == state.originalPasscode) {
      state = state.copyWith(isConfirmed: true);
    } else {
      // Send them back to the start rather than letting them retry the
      // confirmation against a passcode they may have mistyped first time.
      state = state.copyWith(
        enteredPasscode: '',
        stage: PasscodeStage.create,
        clearOriginal: true,
        showError: true,
        errorMessage: 'Passcodes do not match. Please start again.',
      );
    }
  }

  /// The confirmed passcode, or null until both stages match.
  String? get confirmedPasscode =>
      state.isConfirmed ? state.originalPasscode : null;

  void reset() => state = const PasscodeState();
}
