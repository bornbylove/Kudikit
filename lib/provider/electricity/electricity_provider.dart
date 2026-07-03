// lib/provider/electricity/electricity_provider.dart
//
// Defines ElectricityState, ElectricityNotifier, and electricityProvider.
//
// Same root-cause fix as cable_tv_provider.dart:
//   This file previously only re-exported bills_controllers.dart, which
//   re-exported this file — a circular loop with no actual definitions.
//   electricity_screen.dart imported this file and found nothing.

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/model/electricity/electricity_model.dart';

// =============================================================================
// Step enum
// =============================================================================

enum ElectricityStep {
  idle,
  validatingMeter,
  ready,
  processing,
  success,
  failed,
}

// =============================================================================
// State
// =============================================================================

class ElectricityState {
  final ElectricityStep step;

  /// The electricity distribution company selected by the user.
  final ElectricityProviderInfo selectedProvider;

  /// Prepaid or postpaid meter type.
  final MeterType meterType;

  /// Raw meter number typed by the user.
  final String meterNumber;

  /// True while an async meter-validation call is in flight.
  final bool isValidatingMeter;

  /// True if the last meter validation returned an error / invalid result.
  final bool isMeterInvalid;

  /// Account detail returned after a successful meter validation.
  final ElectricityAccountDetail? accountDetail;

  /// Amount entered by the user (or selected from a quick-amount chip).
  final double? amount;

  /// Full payment response returned on success.
  final ElectricityPaymentResponse? result;

  /// Error message from the last failed operation.
  final String? error;

  const ElectricityState({
    this.step = ElectricityStep.idle,
    required this.selectedProvider,
    this.meterType = MeterType.prepaid,
    this.meterNumber = '',
    this.isValidatingMeter = false,
    this.isMeterInvalid = false,
    this.accountDetail,
    this.amount,
    this.result,
    this.error,
  });

  /// Continue button enabled when the user has a validated meter and an amount.
  bool get canContinue =>
      accountDetail != null &&
      !isValidatingMeter &&
      amount != null &&
      amount! >= 100; // minimum NGN 100 for electricity

  ElectricityState copyWith({
    ElectricityStep? step,
    ElectricityProviderInfo? selectedProvider,
    MeterType? meterType,
    String? meterNumber,
    bool? isValidatingMeter,
    bool? isMeterInvalid,
    ElectricityAccountDetail? accountDetail,
    bool clearAccountDetail = false,
    double? amount,
    ElectricityPaymentResponse? result,
    String? error,
    bool clearError = false,
  }) {
    return ElectricityState(
      step: step ?? this.step,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      meterType: meterType ?? this.meterType,
      meterNumber: meterNumber ?? this.meterNumber,
      isValidatingMeter: isValidatingMeter ?? this.isValidatingMeter,
      isMeterInvalid: isMeterInvalid ?? this.isMeterInvalid,
      accountDetail:
          clearAccountDetail ? null : (accountDetail ?? this.accountDetail),
      amount: amount ?? this.amount,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class ElectricityNotifier extends StateNotifier<ElectricityState> {
  final DioClient _client;

  Timer? _meterDebounce;

  ElectricityNotifier(this._client)
      : super(ElectricityState(
          selectedProvider: electricityProviders.first,
        ));

  @override
  void dispose() {
    _meterDebounce?.cancel();
    super.dispose();
  }

  // ── Provider selection ───────────────────────────────────────────────────

  void setProvider(ElectricityProviderInfo provider) {
    state = state.copyWith(
      selectedProvider: provider,
      meterNumber: '',
      isMeterInvalid: false,
      clearAccountDetail: true,
      step: ElectricityStep.idle,
      clearError: true,
    );
  }

  // ── Meter type toggle ────────────────────────────────────────────────────

  void setMeterType(MeterType type) {
    state = state.copyWith(
      meterType: type,
      meterNumber: '',
      isMeterInvalid: false,
      clearAccountDetail: true,
      step: ElectricityStep.idle,
      clearError: true,
    );
  }

  // ── Meter number input ───────────────────────────────────────────────────

  void setMeterNumber(String value) {
    _meterDebounce?.cancel();

    state = state.copyWith(
      meterNumber: value,
      isMeterInvalid: false,
      clearAccountDetail: true,
      step: ElectricityStep.idle,
      clearError: true,
    );

    // Validate once the user has entered a plausible-length meter number
    if (value.length >= 11) {
      _meterDebounce = Timer(const Duration(milliseconds: 800), () {
        _validateMeter(value);
      });
    }
  }

  Future<void> _validateMeter(String meterNumber) async {
    state = state.copyWith(
      isValidatingMeter: true,
      step: ElectricityStep.validatingMeter,
      clearError: true,
    );

    try {
      // ── TODO: replace mock with real DioClient call ──────────────────────
      // final response = await _client.post<Map<String, dynamic>>(
      //   '/bills/electricity/validate',
      //   data: {
      //     'meter_number': meterNumber,
      //     'meter_type': state.meterType.name,
      //     'provider': state.selectedProvider.shortCode,
      //   },
      // );
      // final detail = ElectricityAccountDetail.fromJson(
      //     response.data as Map<String, dynamic>);
      // ────────────────────────────────────────────────────────────────────

      await Future.delayed(const Duration(milliseconds: 1200));
      final detail = ElectricityAccountDetail(
        name: 'JOHN DOE',
        meterNumber: meterNumber,
        meterType: state.meterType,
        provider: state.selectedProvider.name,
        location: 'Lagos, Nigeria',
      );

      state = state.copyWith(
        isValidatingMeter: false,
        isMeterInvalid: false,
        accountDetail: detail,
        step: ElectricityStep.ready,
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        isValidatingMeter: false,
        isMeterInvalid: true,
        clearAccountDetail: true,
        step: ElectricityStep.idle,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isValidatingMeter: false,
        isMeterInvalid: true,
        clearAccountDetail: true,
        step: ElectricityStep.idle,
        error: 'Could not validate meter number. Please try again.',
      );
    }
  }

  // ── Amount input ─────────────────────────────────────────────────────────

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  // ── Payment ──────────────────────────────────────────────────────────────

  Future<void> processPayment(String pin) async {
    if (!state.canContinue) return;

    state = state.copyWith(
      step: ElectricityStep.processing,
      clearError: true,
    );

    try {
      // ── TODO: replace mock with real DioClient call ──────────────────────
      // final response = await _client.post<Map<String, dynamic>>(
      //   '/bills/electricity/pay',
      //   data: {
      //     'meter_number': state.meterNumber,
      //     'meter_type': state.meterType.name,
      //     'provider': state.selectedProvider.shortCode,
      //     'amount': state.amount,
      //     'pin': pin,
      //   },
      // );
      // final result = ElectricityPaymentResponse.fromJson(
      //     response.data as Map<String, dynamic>);
      // ────────────────────────────────────────────────────────────────────

      await Future.delayed(const Duration(seconds: 2));
      final result = ElectricityPaymentResponse(
        success: true,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        message: 'Payment successful',
        token: state.meterType == MeterType.prepaid
            ? '${DateTime.now().millisecondsSinceEpoch}'.substring(0, 10)
            : null,
        amount: state.amount!,
        meterNumber: state.meterNumber,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        step: ElectricityStep.success,
        result: result,
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        step: ElectricityStep.failed,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        step: ElectricityStep.failed,
        error: 'Payment failed. Please try again.',
      );
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _meterDebounce?.cancel();
    state = ElectricityState(selectedProvider: electricityProviders.first);
  }
}

// =============================================================================
// Provider
// =============================================================================

final electricityProvider =
    StateNotifierProvider<ElectricityNotifier, ElectricityState>((ref) {
  return ElectricityNotifier(ref.watch(dioClientProvider));
});
