// lib/provider/auth/sessions_provider.dart
// PRD §2.3.2 Security Settings: "Device Management... Active Sessions: View
// and revoke in security settings" + §2.1.5.4 "Multiple Sessions: Allow 2
// concurrent sessions max." Backed by SecurityService's
// GET/DELETE /security/sessions* (confirmed live — see security_services.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart' show securityServiceProvider;
import 'package:kudipay/services/security_services.dart';

class SessionsState {
  final List<ActiveSession> sessions;
  final bool isLoading;
  final String? error;
  final String? revokingId;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.revokingId,
  });

  SessionsState copyWith({
    List<ActiveSession>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? revokingId,
    bool clearRevokingId = false,
  }) {
    return SessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      revokingId: clearRevokingId ? null : (revokingId ?? this.revokingId),
    );
  }
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final Ref _ref;
  SessionsNotifier(this._ref) : super(const SessionsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = await _ref.read(securityServiceProvider).getSessions();
      state = state.copyWith(isLoading: false, sessions: sessions);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Could not load active sessions.');
    }
  }

  Future<void> revoke(String sessionId) async {
    state = state.copyWith(revokingId: sessionId, clearError: true);
    try {
      await _ref.read(securityServiceProvider).revokeSession(sessionId);
      state = state.copyWith(
        clearRevokingId: true,
        sessions:
            state.sessions.where((s) => s.sessionId != sessionId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
          clearRevokingId: true, error: 'Failed to revoke that session.');
    }
  }

  Future<void> revokeAllOthers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(securityServiceProvider).revokeAllOtherSessions();
      await load();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to revoke other sessions.');
    }
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  return SessionsNotifier(ref);
});
