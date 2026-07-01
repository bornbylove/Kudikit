// lib/provider/transaction/transaction_provider.dart
//
// FIXED (3 issues):
//   1. transactionServiceProvider was passing named params `baseUrl` and
//      `authToken` to TransactionService(), but the class now only accepts a
//      single positional DioClient. Updated to use dioClientProvider instead.
//   2. The large commented-out old implementation at the top of the file has
//      been removed to eliminate the dangling dead code.
//   3. Both StateNotifierProvider and StateProvider come from the legacy import,
//      which is already present — no change needed there, but the import order
//      has been cleaned up for clarity.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/transaction/transaction_model.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/services/transaction_service.dart';

// ==================== TRANSACTION SERVICE PROVIDER ====================

// FIXED: TransactionService takes a single positional DioClient, not named
// baseUrl/authToken params. Use dioClientProvider which already holds the
// configured Dio instance with auth interceptors baked in.
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.read(dioClientProvider));
});

// ==================== TRANSACTION STATE ====================

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      // INTENTIONAL: passing null here clears the error, matching the pattern
      // used throughout the codebase (error: null in copyWith calls).
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ==================== TRANSACTION NOTIFIER ====================

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _service;

  TransactionNotifier(this._service) : super(const TransactionState());

  Future<void> loadTransactions({
    bool refresh = false,
    TransactionStatus? status,
  }) async {
    if (refresh) {
      state = const TransactionState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final transactions = await _service.getTransactions(
        status: status,
        limit: 50,
      );

      state = TransactionState(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      final newTransactions = await _service.getTransactions(
        offset: state.transactions.length,
        limit: 50,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        hasMore: newTransactions.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchTransactions(String query) async {
    if (query.isEmpty) {
      await loadTransactions(refresh: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _service.searchTransactions(query);
      state = TransactionState(
        transactions: transactions,
        isLoading: false,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> downloadTransactions({
    String format = 'pdf',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _service.downloadTransactions(
        format: format,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionNotifier(service);
});

// ==================== TRANSACTION FILTER ====================

class TransactionFilter {
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.status,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionFilter(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final state = ref.watch(transactionProvider);
  final filter = ref.watch(transactionFilterProvider);

  var transactions = state.transactions;

  if (filter.status != null) {
    transactions = transactions
        .where((transaction) => transaction.status == filter.status)
        .toList();
  }

  if (filter.startDate != null) {
    transactions = transactions
        .where((transaction) => transaction.date.isAfter(filter.startDate!))
        .toList();
  }
  if (filter.endDate != null) {
    transactions = transactions
        .where((transaction) => transaction.date.isBefore(filter.endDate!))
        .toList();
  }

  return transactions;
});

final groupedTransactionsProvider =
    Provider<Map<String, List<Transaction>>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, List<Transaction>> grouped = {};

  for (var transaction in transactions) {
    final key = _getDateKey(transaction.date);
    if (!grouped.containsKey(key)) {
      grouped[key] = [];
    }
    grouped[key]!.add(transaction);
  }

  return grouped;
});

String _getDateKey(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final transactionDate = DateTime(date.year, date.month, date.day);

  if (transactionDate == today) {
    return 'Today';
  }

  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final dayName = days[date.weekday - 1];
  final monthName = months[date.month - 1];
  final dayWithSuffix = _getDayWithSuffix(date.day);

  return '$dayName, $monthName $dayWithSuffix, ${date.year}';
}

String _getDayWithSuffix(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

// ==================== TRANSACTION STATS ====================

class TransactionStats {
  final double totalIncome;
  final double totalExpense;
  final int totalTransactions;
  final int successfulCount;
  final int failedCount;
  final int pendingCount;

  TransactionStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransactions,
    required this.successfulCount,
    required this.failedCount,
    required this.pendingCount,
  });

  double get netBalance => totalIncome - totalExpense;
}

final transactionStatsProvider = Provider<TransactionStats>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);

  double totalIncome = 0;
  double totalExpense = 0;
  int successfulCount = 0;
  int failedCount = 0;
  int pendingCount = 0;

  for (final transaction in transactions) {
    if (transaction.type == TransactionType.credit) {
      totalIncome += transaction.amount;
    } else {
      totalExpense += transaction.amount;
    }

    switch (transaction.status) {
      case TransactionStatus.successful:
        successfulCount++;
        break;
      case TransactionStatus.failed:
        failedCount++;
        break;
      case TransactionStatus.pending:
        pendingCount++;
        break;
    }
  }

  return TransactionStats(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalTransactions: transactions.length,
    successfulCount: successfulCount,
    failedCount: failedCount,
    pendingCount: pendingCount,
  );
});