// lib/provider/wallet/wallet_provider.dart
// FIXED (2026-09-19): now sources from DashboardService (GET /dashboard on
// the security/core service, :8181) instead of the old '/wallet/balance' +
// '/wallet/account-details' calls. Those routes don't exist anywhere across
// kudikit_auth_service, Kudikitgateway, or kudikitpayment — confirmed by
// checking every controller in all three repos — so they were never
// reachable. See dashboard_services.dart for the full explanation and the
// backend-source verification that /dashboard's wallet data is real (a live
// Cyclos balance read, not a stub).

import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/provider/wallet/dashboard_provider.dart' show dashboardServiceProvider;
import 'package:kudipay/services/dashboard_services.dart';

class WalletState {
  final double balance;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final bool isLoading;
  final bool isRefreshing;
  final DateTime? lastUpdated;
  final String? error;

  const WalletState({
    this.balance = 0.0,
    this.accountNumber = '',
    this.accountName = '',
    this.bankName = 'Kudikit MFB',
    this.isLoading = false,
    this.isRefreshing = false,
    this.lastUpdated,
    this.error,
  });

  /// Formatted balance string e.g. "50,000.00"
  String get formattedBalance {
    final parts = balance.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final result = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(whole[i]);
      count++;
    }
    return '${result.toString().split('').reversed.join('')}.$decimal';
  }

  /// Two-letter initials derived from accountName.
  String get initials {
    final parts = accountName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'KK';
  }

  WalletState copyWith({
    double? balance,
    String? accountNumber,
    String? accountName,
    String? bankName,
    bool? isLoading,
    bool? isRefreshing,
    DateTime? lastUpdated,
    String? error,
    bool clearError = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final DashboardService _dashboardService;

  WalletNotifier(this._dashboardService) : super(const WalletState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _dashboardService.getDashboardOrThrow();
      state = state.copyWith(
        isLoading: false,
        balance: summary.availableBalance,
        accountNumber: summary.accountNumber,
        accountName: summary.accountName,
        bankName: summary.bankName,
        lastUpdated: summary.lastUpdated ?? DateTime.now(),
      );
    } on KudiNetworkException {
      state = state.copyWith(
          isLoading: false, error: 'No internet. Pull to refresh.');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Could not load wallet. Pull to refresh.');
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final summary = await _dashboardService.getDashboardOrThrow();
      state = state.copyWith(
        isRefreshing: false,
        balance: summary.availableBalance,
        accountNumber: summary.accountNumber,
        accountName: summary.accountName,
        bankName: summary.bankName,
        lastUpdated: summary.lastUpdated ?? DateTime.now(),
      );
    } on KudiNetworkException {
      state =
          state.copyWith(isRefreshing: false, error: 'No internet connection.');
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: 'Refresh failed. Try again.');
    }
  }

  /// Optimistically deduct from local balance after a confirmed payment.
  /// The next refresh() call will reconcile with the server.
  void deduct(double amount) {
    if (state.balance >= amount) {
      state = state.copyWith(balance: state.balance - amount);
    }
  }

  /// Optimistically add to local balance after a confirmed top-up.
  void credit(double amount) {
    state = state.copyWith(balance: state.balance + amount);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.read(dashboardServiceProvider));
});
