// lib/features/request/domain/repositories/request_repository.dart

import 'package:kudipay/features/request/domain/entities/request_model.dart';

/// Split of the caller's requests into the two lists the UI shows.
class MoneyRequestsResult {
  final List<MoneyRequest> sent;
  final List<MoneyRequest> received;

  const MoneyRequestsResult({required this.sent, required this.received});

  const MoneyRequestsResult.empty()
      : sent = const [],
        received = const [];
}

abstract interface class RequestRepository {
  /// Fetches the caller's money requests, already split into sent/received.
  Future<MoneyRequestsResult> getRequests();
}
