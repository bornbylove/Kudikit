// lib/services/session_events.dart
// Tiny event bus so DioClient's auth interceptor (which lives below the
// Riverpod provider graph, to avoid a dioClientProvider <-> authProvider
// circular dependency) can tell AuthNotifier "the session just died"
// without either one holding a reference to the other's provider.

import 'dart:async';

class SessionEvents {
  SessionEvents._();
  static final SessionEvents instance = SessionEvents._();

  final _controller = StreamController<void>.broadcast();

  /// Fires when a refresh-token attempt fails (or no refresh token exists)
  /// after a 401, meaning the session is no longer valid.
  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
