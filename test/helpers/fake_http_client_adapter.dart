// test/helpers/fake_http_client_adapter.dart
//
// A minimal, dependency-free Dio HttpClientAdapter test double. Responses
// are queued per path-substring, FIFO — so a test can queue "401 then 200"
// for the same endpoint to simulate an expired-token-then-refreshed-retry
// sequence without any mocking package.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeResponder = ResponseBody Function(RequestOptions options);

class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, List<FakeResponder>> _queuedByPath = {};
  FakeResponder? fallback;

  /// Queue a response for the next request whose path contains
  /// [pathContains]. Multiple calls queue multiple responses, consumed FIFO.
  void queue(String pathContains, FakeResponder responder) {
    _queuedByPath.putIfAbsent(pathContains, () => []).add(responder);
  }

  void queueJson(String pathContains, int statusCode, Map<String, dynamic> body) {
    queue(pathContains, (_) => jsonResponse(statusCode, body));
  }

  static ResponseBody jsonResponse(int statusCode, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    for (final entry in _queuedByPath.entries) {
      if (options.path.contains(entry.key) && entry.value.isNotEmpty) {
        final responder = entry.value.removeAt(0);
        return responder(options);
      }
    }
    if (fallback != null) return fallback!(options);
    throw StateError(
        'FakeHttpClientAdapter: no response queued for ${options.method} ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}
