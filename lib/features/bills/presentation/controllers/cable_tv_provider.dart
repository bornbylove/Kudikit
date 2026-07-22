// lib/provider/cable_tv/cable_tv_provider.dart
//
// Defines CableTvState, CableTvNotifier, and cableTvProvider.
//
// Root cause of the "Undefined name 'cableTvProvider'" error:
//   This file previously contained only a re-export shim pointing at
//   bills_controllers.dart, which in turn re-exported this file — a circular
//   loop that never actually defined the provider, the state class, or the
//   notifier. cable_tv_screen.dart imported this file and found nothing.
//
// Fix: The full provider is defined here. bills_controllers.dart re-exports
// this file as before, so all existing import paths continue to work.

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/features/bills/domain/entities/cable_tv_model.dart';

// =============================================================================
// Step enum
// =============================================================================

enum CableTvStep {
  idle,
  validatingIuc,
  ready,
  processing,
  success,
  failed,
}

// =============================================================================
// State
// =============================================================================

class CableTvState {
  final CableTvStep step;

  /// The cable TV provider chosen on the biller-selection screen.
  final CableTvProviderInfo selectedProvider;

  /// Plans available for [selectedProvider], loaded from the plan catalogue.
  final List<CableTvPlan> availablePlans;

  /// The plan the user has chosen, or null if none selected yet.
  final CableTvPlan? selectedPlan;

  /// Raw IUC/decoder number typed by the user.
  final String iucNumber;

  /// True while an async IUC-validation call is in flight.
  final bool isValidatingIuc;

  /// True if the last IUC validation returned an error / invalid result.
  final bool isIucInvalid;

  /// Account detail returned by a successful IUC validation.
  final CableTvAccountDetail? accountDetail;

  /// Amount to charge (mirrors selectedPlan.amount when a plan is chosen).
  final double? amount;

  /// Whether the user has toggled auto-renewal on.
  final bool autoRenew;

  /// Transaction ID returned after a successful payment.
  final String? transactionId;

  /// Error message from the last failed operation.
  final String? error;

  const CableTvState({
    this.step = CableTvStep.idle,
    required this.selectedProvider,
    this.availablePlans = const [],
    this.selectedPlan,
    this.iucNumber = '',
    this.isValidatingIuc = false,
    this.isIucInvalid = false,
    this.accountDetail,
    this.amount,
    this.autoRenew = false,
    this.transactionId,
    this.error,
  });

  /// The Continue button is enabled when the user has:
  ///   • a valid (validated) IUC, and
  ///   • a selected plan or a manually entered amount.
  bool get canContinue =>
      accountDetail != null &&
      !isValidatingIuc &&
      (selectedPlan != null || (amount != null && amount! > 0));

  CableTvState copyWith({
    CableTvStep? step,
    CableTvProviderInfo? selectedProvider,
    List<CableTvPlan>? availablePlans,
    CableTvPlan? selectedPlan,
    bool clearPlan = false,
    String? iucNumber,
    bool? isValidatingIuc,
    bool? isIucInvalid,
    CableTvAccountDetail? accountDetail,
    bool clearAccountDetail = false,
    double? amount,
    bool? autoRenew,
    String? transactionId,
    String? error,
    bool clearError = false,
  }) {
    return CableTvState(
      step: step ?? this.step,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: clearPlan ? null : (selectedPlan ?? this.selectedPlan),
      iucNumber: iucNumber ?? this.iucNumber,
      isValidatingIuc: isValidatingIuc ?? this.isValidatingIuc,
      isIucInvalid: isIucInvalid ?? this.isIucInvalid,
      accountDetail:
          clearAccountDetail ? null : (accountDetail ?? this.accountDetail),
      amount: amount ?? this.amount,
      autoRenew: autoRenew ?? this.autoRenew,
      transactionId: transactionId ?? this.transactionId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class CableTvNotifier extends StateNotifier<CableTvState> {
  // Injected client reserved for the live cable-TV API (see stubbed calls below).
  // ignore: unused_field
  final DioClient _client;

  /// Debounce timer so IUC validation only fires after the user stops typing.
  Timer? _iucDebounce;

  CableTvNotifier(this._client)
      : super(CableTvState(
          selectedProvider: cableTvProviders.first,
        ));

  @override
  void dispose() {
    _iucDebounce?.cancel();
    super.dispose();
  }

  // ── Provider selection (biller screen → detail screen) ──────────────────

  void setProvider(CableTvProviderInfo provider) {
    final plans = getPlansForProvider(provider.provider);
    state = state.copyWith(
      selectedProvider: provider,
      availablePlans: plans,
      clearPlan: true,
      clearAccountDetail: true,
      iucNumber: '',
      isIucInvalid: false,
      step: CableTvStep.idle,
      clearError: true,
    );
  }

  // ── IUC input ────────────────────────────────────────────────────────────

  void setIucNumber(String value) {
    _iucDebounce?.cancel();

    // Reset validation state while the user is typing
    state = state.copyWith(
      iucNumber: value,
      isIucInvalid: false,
      clearAccountDetail: true,
      step: CableTvStep.idle,
      clearError: true,
    );

    // Validate once the user has entered a plausible-length IUC
    if (value.length >= 10) {
      _iucDebounce = Timer(const Duration(milliseconds: 800), () {
        _validateIuc(value);
      });
    }
  }

  Future<void> _validateIuc(String iucNumber) async {
    state = state.copyWith(
      isValidatingIuc: true,
      step: CableTvStep.validatingIuc,
      clearError: true,
    );

    try {
      // ── TODO: replace mock with real DioClient call ──────────────────────
      // final response = await _client.post<Map<String, dynamic>>(
      //   '/bills/cable-tv/validate',
      //   data: {
      //     'iuc_number': iucNumber,
      //     'provider': state.selectedProvider.provider.name,
      //   },
      // );
      // final detail = CableTvAccountDetail.fromJson(
      //     response.data as Map<String, dynamic>);
      // ────────────────────────────────────────────────────────────────────

      // Mock: simulate network latency and return a plausible account
      await Future.delayed(const Duration(milliseconds: 1200));
      final detail = CableTvAccountDetail(
        name: 'JOHN DOE',
        decoderNumber: iucNumber,
        provider: state.selectedProvider.name,
        currentPlan: state.selectedPlan?.name ?? 'None',
        isExpired: false,
      );

      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: false,
        accountDetail: detail,
        step: CableTvStep.ready,
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: true,
        clearAccountDetail: true,
        step: CableTvStep.idle,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: true,
        clearAccountDetail: true,
        step: CableTvStep.idle,
        error: 'Could not validate IUC. Please try again.',
      );
    }
  }

  // ── Plan selection ───────────────────────────────────────────────────────

  void selectPlan(CableTvPlan plan) {
    state = state.copyWith(
      selectedPlan: plan,
      amount: plan.amount,
    );
  }

  // ── Amount (manual override) ─────────────────────────────────────────────

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  // ── Auto-renew toggle ────────────────────────────────────────────────────

  void toggleAutoRenew() {
    state = state.copyWith(autoRenew: !state.autoRenew);
  }

  // ── Payment ──────────────────────────────────────────────────────────────

  Future<void> processPayment(String pin) async {
    if (!state.canContinue) return;

    state = state.copyWith(
      step: CableTvStep.processing,
      clearError: true,
    );

    try {
      // ── TODO: replace mock with real DioClient call ──────────────────────
      // final response = await _client.post<Map<String, dynamic>>(
      //   '/bills/cable-tv/pay',
      //   data: {
      //     'iuc_number': state.iucNumber,
      //     'provider': state.selectedProvider.provider.name,
      //     'plan_id': state.selectedPlan?.id,
      //     'amount': state.selectedPlan?.amount ?? state.amount,
      //     'auto_renew': state.autoRenew,
      //     'pin': pin,
      //   },
      // );
      // final txnId = (response.data as Map<String, dynamic>)['transaction_id']
      //     as String?;
      // ────────────────────────────────────────────────────────────────────

      await Future.delayed(const Duration(seconds: 2));
      final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      state = state.copyWith(
        step: CableTvStep.success,
        transactionId: txnId,
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        step: CableTvStep.failed,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        step: CableTvStep.failed,
        error: 'Payment failed. Please try again.',
      );
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _iucDebounce?.cancel();
    state = CableTvState(selectedProvider: cableTvProviders.first);
  }
}

// =============================================================================
// Provider
// =============================================================================

final cableTvProvider =
    StateNotifierProvider<CableTvNotifier, CableTvState>((ref) {
  return CableTvNotifier(ref.watch(dioClientProvider));
});
