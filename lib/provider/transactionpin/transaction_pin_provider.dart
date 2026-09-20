import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart' show securityServiceProvider;
import 'package:kudipay/services/security_services.dart';
import 'package:kudipay/services/transaction_pin_service.dart';
import 'package:flutter_riverpod/legacy.dart';

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
  final String? errorMessage;

  const TxPinSetupState({
    this.firstPin = '',
    this.enteredPin = '',
    this.isConfirmStep = false,
    this.showError = false,
    this.isLoading = false,
    this.isComplete = false,
    this.errorMessage,
  });

  TxPinSetupState copyWith({
    String? firstPin,
    String? enteredPin,
    bool? isConfirmStep,
    bool? showError,
    bool? isLoading,
    bool? isComplete,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TxPinSetupState(
      firstPin: firstPin ?? this.firstPin,
      enteredPin: enteredPin ?? this.enteredPin,
      isConfirmStep: isConfirmStep ?? this.isConfirmStep,
      showError: showError ?? this.showError,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TxPinSetupNotifier extends StateNotifier<TxPinSetupState> {
  final TransactionPinService _service;
  final SecurityService _securityService;
  TxPinSetupNotifier(this._service, this._securityService)
      : super(const TxPinSetupState());

  static const int _pinLength = 4;
  bool _isMounted = true;

  void addDigit(String digit) {
    if (state.enteredPin.length >= _pinLength || state.isLoading) return;
    final newPin = state.enteredPin + digit;
    state = state.copyWith(enteredPin: newPin, showError: false);
    if (newPin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), () => _onPinComplete(newPin));
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
      state = state.copyWith(firstPin: pin, enteredPin: '', isConfirmStep: true, showError: false);
    } else {
      if (pin == state.firstPin) {
        state = state.copyWith(isLoading: true, clearErrorMessage: true);
        try {
          // FIX: this used to only save locally — POST /security/pin/create
          // is confirmed live (kudikit's security/core service) and is the
          // only place a user's transaction PIN gets recorded server-side.
          // The local hash is kept too, as the fast client-side check
          // transaction_pin_bottom_sheet.dart already relies on.
          await _securityService.createTransactionPin(
              pin: pin, confirmPin: pin);
          await _service.saveTransactionPin(pin);
          if (_isMounted) state = state.copyWith(isLoading: false, isComplete: true);
        } on KudiApiException catch (e) {
          if (_isMounted) {
            state = state.copyWith(
                isLoading: false,
                showError: true,
                enteredPin: '',
                errorMessage: e.message);
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (_isMounted) {
                state = state.copyWith(showError: false, clearErrorMessage: true);
              }
            });
          }
        } catch (_) {
          if (_isMounted) {
            state = state.copyWith(isLoading: false, showError: true, enteredPin: '');
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

final txPinSetupProvider = StateNotifierProvider<TxPinSetupNotifier, TxPinSetupState>((ref) {
  final service = ref.read(transactionPinServiceProvider);
  final securityService = ref.read(securityServiceProvider);
  return TxPinSetupNotifier(service, securityService);
});

final hasTxPinProvider = FutureProvider<bool>((ref) async {
  return ref.read(transactionPinServiceProvider).hasTransactionPin();
});