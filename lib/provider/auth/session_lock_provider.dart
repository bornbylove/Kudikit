// lib/provider/auth/session_lock_provider.dart
// PRD §2.1.5.4 Session Management: "Auto-logout: Configurable per tier —
// Tier 1: 3 min, Tier 2: 5 min, Tier 3: 10 min. Warning shows 60 seconds
// before auto-logout. Tap extends session by another period."
//
// This does NOT destroy the session (no /auth/logout call, tokens kept) —
// it re-locks the app behind AppLockScreen, which unlocks via biometrics or
// the local passcode (matches how PRD §2.1.5.3's "Biometric prompt appears
// if previously enrolled" makes sense as a *return-to-app* gate rather than
// a full re-login). A real server-side session end still happens through
// the existing SessionEvents.onSessionExpired path (refresh-token failure)
// or an explicit user-initiated logout — neither of those is this file's
// concern.
//
// Two triggers feed the same lock:
//   1. In-foreground idle timer (ticks while the app is open and unused).
//   2. Backgrounded-too-long, checked on app resume (main.dart wires this
//      via WidgetsBindingObserver.didChangeAppLifecycleState).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart';

enum SessionLockPhase { unlocked, warning, locked }

class SessionLockState {
  final SessionLockPhase phase;
  final Duration timeout;

  const SessionLockState({
    required this.phase,
    required this.timeout,
  });

  SessionLockState copyWith({SessionLockPhase? phase, Duration? timeout}) {
    return SessionLockState(
      phase: phase ?? this.phase,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// Warning window before the lock fires — PRD: "Warning shows 60 seconds
/// before auto-logout."
const _warningWindow = Duration(seconds: 60);

/// PRD-specified per-tier default, used until /security/settings resolves
/// (and as the permanent fallback if it never does — e.g. offline).
Duration _defaultTimeoutForTier(int grantedTier) {
  switch (grantedTier) {
    case 2:
      return const Duration(minutes: 5);
    case 3:
      return const Duration(minutes: 10);
    default:
      return const Duration(minutes: 3);
  }
}

class SessionLockNotifier extends StateNotifier<SessionLockState> {
  final Ref _ref;
  Timer? _ticker;
  DateTime _lastActivity = DateTime.now();

  /// Set only while the app is genuinely open and past the lock gate —
  /// main.dart must not call recordActivity()/tick() before the user has
  /// unlocked once, or before login.
  bool _armed = false;

  SessionLockNotifier(this._ref)
      : super(SessionLockState(
          phase: SessionLockPhase.unlocked,
          timeout: const Duration(minutes: 3),
        ));

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Starts the idle timer. Call once, right after the user unlocks (or
  /// logs in fresh) — a no-op if already armed.
  Future<void> arm() async {
    if (_armed) return;
    _armed = true;
    _lastActivity = DateTime.now();

    final grantedTier = _ref.read(currentUserProvider)?.grantedTierOrZero ?? 1;
    var timeout = _defaultTimeoutForTier(grantedTier);

    // Best-effort server override — never blocks arming on it.
    unawaited(_ref.read(securityServiceProvider).getSecuritySettings().then((s) {
      if (s != null && s.sessionTimeoutSeconds > 0) {
        timeout = Duration(seconds: s.sessionTimeoutSeconds);
        state = state.copyWith(timeout: timeout);
      }
    }));

    state = SessionLockState(phase: SessionLockPhase.unlocked, timeout: timeout);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Stops the idle timer entirely — call on real logout so a locked
  /// LoginPage never gets shown after the session is actually gone.
  void disarm() {
    _armed = false;
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(phase: SessionLockPhase.unlocked);
  }

  /// Any user interaction (tap, scroll, keystroke) resets the idle clock.
  /// No-op while already locked — only a successful unlock clears that.
  void recordActivity() {
    if (!_armed || state.phase == SessionLockPhase.locked) return;
    _lastActivity = DateTime.now();
    if (state.phase == SessionLockPhase.warning) {
      state = state.copyWith(phase: SessionLockPhase.unlocked);
    }
  }

  void _tick() {
    if (!_armed || state.phase == SessionLockPhase.locked) return;
    final idleFor = DateTime.now().difference(_lastActivity);
    final untilLock = state.timeout - idleFor;

    if (untilLock <= Duration.zero) {
      state = state.copyWith(phase: SessionLockPhase.locked);
    } else if (untilLock <= _warningWindow &&
        state.phase != SessionLockPhase.warning) {
      state = state.copyWith(phase: SessionLockPhase.warning);
    }
  }

  /// Called from main.dart's lifecycle observer when the app resumes —
  /// backgrounding doesn't pause the wall-clock, so a long background stint
  /// should lock immediately rather than wait for the next foreground tick.
  void onAppResumed() {
    if (!_armed) return;
    _tick();
  }

  /// Force-lock immediately (e.g. app backgrounded past the timeout, or a
  /// manual "lock now" action) without waiting for the next tick.
  void lockNow() {
    if (!_armed) return;
    state = state.copyWith(phase: SessionLockPhase.locked);
  }

  /// Called by AppLockScreen after a successful biometric or passcode check.
  void unlock() {
    _lastActivity = DateTime.now();
    state = state.copyWith(phase: SessionLockPhase.unlocked);
  }
}

final sessionLockProvider =
    StateNotifierProvider<SessionLockNotifier, SessionLockState>((ref) {
  return SessionLockNotifier(ref);
});
