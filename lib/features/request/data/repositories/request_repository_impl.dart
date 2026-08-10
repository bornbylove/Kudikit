// lib/features/request/data/repositories/request_repository_impl.dart
//
// Moved out of RequestProvider, which was calling DioClient directly from the
// presentation layer.
//
// NOTE: /requests is not part of the auth/KYC OpenAPI spec, so the response
// shape below is carried over verbatim from the previous inline call rather
// than verified. The `requesterId == 'current_user_id'` sentinel is likewise
// pre-existing — see the comment on [_splitByRequester].

import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/features/request/domain/entities/request_model.dart';
import 'package:kudipay/features/request/domain/repositories/request_repository.dart';

class RequestRepositoryImpl implements RequestRepository {
  final DioClient _client;

  const RequestRepositoryImpl(this._client);

  @override
  Future<MoneyRequestsResult> getRequests() async {
    final response = await _client.get<Map<String, dynamic>>('/requests');
    final raw = (response.data?['requests'] as List<dynamic>?) ?? const [];

    final requests = raw
        .map((r) => MoneyRequest.fromJson(r as Map<String, dynamic>))
        .toList();

    return _splitByRequester(requests);
  }

  // TODO: 'current_user_id' is a placeholder inherited from the original
  // inline implementation — it will never match a real requesterId, so every
  // request currently lands in `received`. Needs the authenticated user's id.
  MoneyRequestsResult _splitByRequester(List<MoneyRequest> requests) {
    final sent = <MoneyRequest>[];
    final received = <MoneyRequest>[];

    for (final request in requests) {
      if (request.requesterId == 'current_user_id') {
        sent.add(request);
      } else {
        received.add(request);
      }
    }

    return MoneyRequestsResult(sent: sent, received: received);
  }
}
