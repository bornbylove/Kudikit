// lib/provider/refresh/refresh_provider.dart
// =============================================================================
// PULL-TO-REFRESH ORCHESTRATOR
// =============================================================================
// WHY THE FIX:
// ─────────────
// Previously every method accepted a `Ref ref` parameter so the notifier could
// read other providers. That caused the compile error:
//
//   The argument type 'WidgetRef' can't be assigned to the parameter type
//   'Ref<Object?>'.
//
// Root cause: `WidgetRef` (the ref you get inside a ConsumerWidget/
// ConsumerStatefulWidget) and `Ref` (the ref passed to a provider factory) are
// different types in Riverpod. They share the same API but are not assignable.
//
// THE CORRECT PATTERN:
// ─────────────────────
// A StateNotifier already receives a `Ref` at construction time via the
// provider factory:
//
//   StateNotifierProvider<RefreshNotifier, RefreshState>((ref) {
//     return RefreshNotifier(ref);   // ← pass it here
//   });
//
// Store that `ref` as a field and use it internally. Methods take NO ref
// parameter. Call sites become simply:
//
//   onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
//
// No type mismatch, no passing refs across widget/provider boundaries.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';
import 'package:kudipay/provider/transaction/transaction_provider.dart';
import 'package:kudipay/provider/request/request_provider.dart';
import 'package:kudipay/provider/funding/funding_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
// ─────────────────────────────────────────────────────────────────────────────
// RefreshState
// ─────────────────────────────────────────────────────────────────────────────

class RefreshState {
  final bool isRefreshing;
  final DateTime? lastRefreshedAt;
  final String? error;

  const RefreshState({
    this.isRefreshing = false,
    this.lastRefreshedAt,
    this.error,
  });

  RefreshState copyWith({
    bool? isRefreshing,
    DateTime? lastRefreshedAt,
    String? error,
    bool clearError = false,
  }) {
    return RefreshState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Human-readable "Updated X ago" string for the balance card subtitle.
  String get lastUpdatedLabel {
    if (lastRefreshedAt == null) return 'Not yet refreshed';
    final diff = DateTime.now().difference(lastRefreshedAt!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RefreshNotifier
// ─────────────────────────────────────────────────────────────────────────────

class RefreshNotifier extends StateNotifier<RefreshState> {
  // Store the Ref passed in by the provider factory.
  // This is the CORRECT Riverpod Ref type — no WidgetRef ever crosses this boundary.
  final Ref _ref;

  RefreshNotifier(this._ref) : super(const RefreshState());

  // ── Full refresh ────────────────────────────────────────────────────────────
  // Call sites (widgets):
  //   onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
  //
  Future<void> refreshAll() async {
    if (state.isRefreshing) return; // guard against double-trigger
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      // All calls fire IN PARALLEL — total time = slowest single call.
      await Future.wait([
        // ── Core financial data ──────────────────────────────────────────────
        _ref.read(walletProvider.notifier).refresh(),

        // ── Transaction history ──────────────────────────────────────────────
        _ref.read(transactionProvider.notifier).loadTransactions(refresh: true),

        // ── Money requests (sent & received) ────────────────────────────────
        _ref.read(requestProvider.notifier).loadRequests(),

        // ── Account details (bank number for Add Money / QR screens) ─────────
        _ref.read(accountDetailsProvider.notifier).loadAccountDetails(),

        // ── Future providers — uncomment as features are built ───────────────
        // _ref.read(notificationProvider.notifier).refresh(),
        // _ref.read(savingsProvider.notifier).refresh(),
      ]);

      state = state.copyWith(
        isRefreshing: false,
        lastRefreshedAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Some data could not be refreshed. Please try again.',
      );
    }
  }

  // ── Scoped refreshes ────────────────────────────────────────────────────────
  // Use after a specific action instead of firing the full refresh.

  /// Refreshes only wallet balance — fast, call after a successful payment.
  Future<void> refreshWalletOnly() async {
    await _ref.read(walletProvider.notifier).refresh();
    state = state.copyWith(lastRefreshedAt: DateTime.now());
  }

  /// Refreshes only the transaction list.
  Future<void> refreshTransactionsOnly() async {
    await _ref
        .read(transactionProvider.notifier)
        .loadTransactions(refresh: true);
    state = state.copyWith(lastRefreshedAt: DateTime.now());
  }

  /// Refreshes only money requests.
  Future<void> refreshRequestsOnly() async {
    await _ref.read(requestProvider.notifier).loadRequests();
    state = state.copyWith(lastRefreshedAt: DateTime.now());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider — passes Ref to the notifier at construction time
// ─────────────────────────────────────────────────────────────────────────────

final refreshProvider =
    StateNotifierProvider<RefreshNotifier, RefreshState>((ref) {
  return RefreshNotifier(ref); // ← ref is Riverpod's own Ref, correct type
});

/// Convenience — expose just the timestamp for "Last updated X ago" widgets.
final lastRefreshedProvider = Provider<DateTime?>((ref) {
  return ref.watch(refreshProvider).lastRefreshedAt;
});
