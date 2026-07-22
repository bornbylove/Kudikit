// lib/services/transaction_service.dart
// INTEGRATED: All methods now make real HTTP calls via DioClient.
// Mock implementations preserved in comments.
//
// Endpoints:
//   GET  /transactions                → list with optional filters
//   GET  /transactions/:id            → single transaction
//   GET  /transactions/search?q=      → search
//   GET  /transactions/download       → export PDF/CSV download URL
//
// FIXED: Constructor now takes only DioClient (removed stale baseUrl/authToken
// named params that no longer exist — DioClient handles auth internally via its
// interceptor chain).

import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/features/transaction/domain/entities/transaction_model.dart';

class TransactionService {
  final DioClient _client;

  // FIXED: single positional DioClient parameter — matches DioClient-based
  // architecture used by every other service in the project.
  TransactionService(this._client);

  /// Fetch paginated/filtered transaction list.
  Future<List<Transaction>> getTransactions({
    int? limit,
    int? offset,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (status != null) 'status': status.value,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _client.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: params.isNotEmpty ? params : null,
      );

      final body = response.data!;
      // Accept both { transactions: [...] } and a bare list
      final raw =
          (body['transactions'] ?? body['data'] ?? body) as List<dynamic>;
      return raw
          .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is KudiNetworkException || e is KudiTimeoutException) rethrow;
      throw TransactionException(
          'Failed to load transactions: ${e.toString()}');
    }
  }

  /// Fetch a single transaction by ID.
  Future<Transaction> getTransactionById(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/transactions/$id');
      return Transaction.fromJson(response.data!);
    } catch (e) {
      throw TransactionException('Failed to load transaction: ${e.toString()}');
    }
  }

  /// Full-text search across the user's transactions.
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/transactions/search',
        queryParameters: {'q': query},
      );
      final raw = (response.data!['transactions'] ??
          response.data!['data'] ??
          response.data!) as List<dynamic>;
      return raw
          .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw TransactionException('Search failed: ${e.toString()}');
    }
  }

  /// Request a download URL for exported transactions (PDF or CSV).
  Future<String> downloadTransactions({
    String format = 'pdf',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{
        'format': format,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };
      final response = await _client.get<Map<String, dynamic>>(
        '/transactions/download',
        queryParameters: params,
      );
      return response.data!['download_url'] as String;
    } catch (e) {
      throw TransactionException('Download failed: ${e.toString()}');
    }
  }
}

class TransactionException implements Exception {
  final String message;
  final int? statusCode;
  TransactionException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
