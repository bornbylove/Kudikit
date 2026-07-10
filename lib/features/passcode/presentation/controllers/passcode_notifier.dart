import 'package:kudipay/features/passcode/domain/passcode_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class PasscodeNotifier extends StateNotifier<PasscodeState> {
  PasscodeNotifier() : super(PasscodeState(originalPasscode: '1234'));

  int _requestId = 0;

  void addDigit(String digit) {
    if (state.enteredPasscode.length < 4) {
      final newPasscode = state.enteredPasscode + digit;

      state = state.copyWith(
        enteredPasscode: newPasscode,
        showError: false,
      );

      if (newPasscode.length == 4) {
        _validatePasscode(newPasscode);
      }
    }
  }

  void removeDigit() {
    if (state.enteredPasscode.isNotEmpty) {
      state = state.copyWith(
        enteredPasscode: state.enteredPasscode
            .substring(0, state.enteredPasscode.length - 1),
        showError: false,
      );
    }
  }

  void _validatePasscode(String passcode) {
    final currentRequest = ++_requestId;

    state = state.copyWith(isLoading: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (currentRequest != _requestId) return;

      if (passcode == state.originalPasscode) {
        state = state.copyWith(
          isConfirmed: true,
          showError: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          showError: true,
          isLoading: false,
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (currentRequest != _requestId) return;

          state = state.copyWith(
            enteredPasscode: '',
            showError: false,
          );
        });
      }
    });
  }

  void reset() {
    _requestId++; // cancel pending validations
    state = PasscodeState(originalPasscode: state.originalPasscode);
  }
}
