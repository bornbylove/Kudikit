// lib/services/dashboard_services.dart
// Client for GET /api/v1/dashboard on kudikit's security/core service
// (confirmed live at 199.192.22.72:8181/v3/api-docs — same host already
// proven working end-to-end for /security/biometric/* — see
// biometric_provider.dart). Identity comes from the Authorization header
// only — no userId path param, so unlike the payments-service's
// /wallets/{userId}/balance (port 8087) this carries no risk of a
// cross-service ID mismatch.
//
// Also now the PRIMARY source for wallet_provider.dart's balance/account
// display (2026-09-19 fix): the old '/wallet/balance' + '/wallet/account-
// details' calls (singular, no path param) hit authDioClientProvider (host
// :8090) and don't exist ANYWHERE across all three backend repos — checked
// every controller in kudikit_auth_service, Kudikitgateway, and
// kudikitpayment. Same class of bug as the old AuthService.getProfile()
// (see api_config.dart), just on the primary dashboard balance instead of
// a secondary field. Verified against Kudikitgateway's own source
// (DashboardServiceImpl.buildWalletSummary) that /dashboard's `wallet`
// object is fully wired — it reads a LIVE Cyclos balance via
// KudikitPaymentClient.getBalance(), not a stale local mirror — so this is
// a safe, complete replacement, not a partial one.

import 'package:kudipay/config/dio_client.dart';

class DashboardQuickStats {
  final int totalTransactions;
  final double todaySpent;
  final double todayReceived;
  final double monthlySpent;

  const DashboardQuickStats({
    this.totalTransactions = 0,
    this.todaySpent = 0,
    this.todayReceived = 0,
    this.monthlySpent = 0,
  });

  factory DashboardQuickStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardQuickStats();
    return DashboardQuickStats(
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      todaySpent: (json['todaySpent'] as num?)?.toDouble() ?? 0,
      todayReceived: (json['todayReceived'] as num?)?.toDouble() ?? 0,
      monthlySpent: (json['monthlySpent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardSummary {
  final double availableBalance;
  final double ledgerBalance;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final DateTime? lastUpdated;
  final DashboardQuickStats quickStats;

  const DashboardSummary({
    required this.availableBalance,
    required this.ledgerBalance,
    this.accountNumber = '',
    this.accountName = '',
    this.bankName = 'Kudikit MFB',
    this.lastUpdated,
    required this.quickStats,
  });

  /// PRD §2.2.1 AC#6: "Pending Balance" separate from "Available Balance".
  /// The wallet-service (port 8087) schema names this `reservedAmount`
  /// directly; this endpoint doesn't expose that field by name, but the
  /// ledger/available delta is the same figure in standard ledger
  /// accounting (funds counted in the ledger but not yet available to
  /// spend) — clamped to 0 since a negative delta shouldn't render as a
  /// negative pending amount.
  double get pendingBalance {
    final delta = ledgerBalance - availableBalance;
    return delta > 0 ? delta : 0;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] as Map<String, dynamic>?;
    return DashboardSummary(
      availableBalance: (wallet?['availableBalance'] as num?)?.toDouble() ?? 0,
      ledgerBalance: (wallet?['ledgerBalance'] as num?)?.toDouble() ?? 0,
      accountNumber: wallet?['accountNumber'] as String? ?? '',
      accountName: wallet?['accountName'] as String? ?? '',
      bankName: (wallet?['bankName'] as String?) ?? 'KudiPay MFB',
      lastUpdated: DateTime.tryParse(wallet?['lastUpdated'] as String? ?? ''),
      quickStats: DashboardQuickStats.fromJson(
          json['quickStats'] as Map<String, dynamic>?),
    );
  }
}

class DashboardService {
  final DioClient _client;
  DashboardService(this._client);

  /// Throws (KudiNetworkException / KudiApiException / KudiServerException —
  /// see dio_client.dart) on failure — used by wallet_provider.dart, where
  /// this is the PRIMARY balance source and the caller needs to distinguish
  /// "no internet" from "server error" for its own error messaging.
  Future<DashboardSummary> getDashboardOrThrow() async {
    final response = await _client.get<Map<String, dynamic>>('/dashboard');
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw KudiApiException('Dashboard response had no data.');
    }
    return DashboardSummary.fromJson(data);
  }

  /// Returns null on any failure — for supplementary data (pending balance +
  /// quick stats on the dashboard card), where callers should hide those UI
  /// sections rather than block on it.
  Future<DashboardSummary?> getDashboard() async {
    try {
      return await getDashboardOrThrow();
    } catch (_) {
      return null;
    }
  }
}
