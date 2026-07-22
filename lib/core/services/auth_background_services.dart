// lib/core/services/auth_background_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Intended to maintain auth in the background (e.g. silent token refresh while
// the app is backgrounded). A background-scheduler dependency (e.g. workmanager)
// is NOT yet declared in pubspec.yaml.
// ─────────────────────────────────────────────────────────────────────────────

/// Background auth maintenance. All methods are stubs pending implementation.
class AuthBackgroundService {
  const AuthBackgroundService();

  /// TODO: schedule periodic background auth/token refresh.
  Future<void> registerPeriodicRefresh() async {
    throw UnimplementedError(
        'AuthBackgroundService.registerPeriodicRefresh is a stub.');
  }

  /// TODO: cancel any scheduled background work.
  Future<void> cancelAll() async {
    throw UnimplementedError('AuthBackgroundService.cancelAll is a stub.');
  }
}
