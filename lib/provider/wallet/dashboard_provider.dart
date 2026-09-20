// lib/provider/wallet/dashboard_provider.dart
// dashboardServiceProvider backs both walletProvider (primary balance —
// see wallet_provider.dart's 2026-09-19 fix) and dashboardSummaryProvider
// below (supplementary pending-balance/quick-stats data). See
// dashboard_services.dart for the full routing-bug history.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart' show securityDioClientProvider;
import 'package:kudipay/services/dashboard_services.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.read(securityDioClientProvider));
});

/// autoDispose + refreshable via ref.invalidate/ref.refresh from pull-to-
/// refresh — matches the rest of the dashboard's refresh_provider pattern
/// without adding a second StateNotifier for what's read-only, best-effort
/// supplementary data.
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary?>((ref) {
  return ref.read(dashboardServiceProvider).getDashboard();
});
