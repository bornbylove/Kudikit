import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/features/transactionpin/data/transaction_pin_service.dart';

import 'package:flutter_riverpod/legacy.dart'; // keep existing

final transactionPinServiceProvider = Provider<TransactionPinService>((ref) {
  return TransactionPinService.instance;
});

class TxPinSetupState {
  final String firstPin;
  final String enteredPin;
  final bool isConfirmStep;
  final bool showError;
  final bool isLoading;
  final bool isComplete;

  const TxPinSetupState({
    this.firstPin = '',
    this.enteredPin = '',
    this.isConfirmStep = false,
    this.showError = false,
    this.isLoading = false,
    this.isComplete = false,
  });

  TxPinSetupState copyWith({
    String? firstPin,
    String? enteredPin,
    bool? isConfirmStep,
    bool? showError,
    bool? isLoading,
    bool? isComplete,
  }) {
    return TxPinSetupState(
      firstPin: firstPin ?? this.firstPin,
      enteredPin: enteredPin ?? this.enteredPin,
      isConfirmStep: isConfirmStep ?? this.isConfirmStep,
      showError: showError ?? this.showError,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class TxPinSetupNotifier extends StateNotifier<TxPinSetupState> {
  final TransactionPinService _service;
  TxPinSetupNotifier(this._service) : super(const TxPinSetupState());

  static const int _pinLength = 4;
  bool _isMounted = true;

  void addDigit(String digit) {
    if (state.enteredPin.length >= _pinLength || state.isLoading) return;
    final newPin = state.enteredPin + digit;
    state = state.copyWith(enteredPin: newPin, showError: false);
    if (newPin.length == _pinLength) {
      Future.delayed(
          const Duration(milliseconds: 200), () => _onPinComplete(newPin));
    }
  }

  void removeDigit() {
    if (state.enteredPin.isEmpty || state.isLoading) return;
    state = state.copyWith(
      enteredPin: state.enteredPin.substring(0, state.enteredPin.length - 1),
      showError: false,
    );
  }

  Future<void> _onPinComplete(String pin) async {
    if (!state.isConfirmStep) {
      state = state.copyWith(
          firstPin: pin, enteredPin: '', isConfirmStep: true, showError: false);
    } else {
      if (pin == state.firstPin) {
        state = state.copyWith(isLoading: true);
        try {
          await _service.saveTransactionPin(pin);
          if (_isMounted) {
            state = state.copyWith(isLoading: false, isComplete: true);
          }
        } catch (_) {
          if (_isMounted) {
            state = state.copyWith(
                isLoading: false, showError: true, enteredPin: '');
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isMounted) state = state.copyWith(showError: false);
            });
          }
        }
      } else {
        state = state.copyWith(showError: true, enteredPin: '');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isMounted) state = state.copyWith(showError: false);
        });
      }
    }
  }

  void reset() => state = const TxPinSetupState();

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
}

final txPinSetupProvider =
    StateNotifierProvider<TxPinSetupNotifier, TxPinSetupState>((ref) {
  final service = ref.read(transactionPinServiceProvider);
  return TxPinSetupNotifier(service);
});

final hasTxPinProvider = FutureProvider<bool>((ref) async {
  return ref.read(transactionPinServiceProvider).hasTransactionPin();
});
