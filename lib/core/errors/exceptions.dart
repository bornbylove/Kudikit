// lib/core/errors/exceptions.dart
// ─────────────────────────────────────────────────────────────────────────────
// Canonical exception hierarchy for all KudiPay network and service errors.
//
// USAGE:
//   import 'package:kudipay/core/errors/exceptions.dart';
//
//   try {
//     await client.get('/endpoint');
//   } on KudiNetworkException {
//     showNoInternet();
//   } on KudiUnauthorizedException {
//     navigateToLogin();
//   } on KudiApiException catch (e) {
//     showError(e.message);
//   }
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all KudiPay exceptions.
/// Catch this to handle any KudiPay-originated error in one clause.
sealed class KudiException implements Exception {
  final String message;
  const KudiException(this.message);

  @override
  String toString() => message;
}

/// No internet connection — device is offline or cannot reach any server.
class KudiNetworkException extends KudiException {
  const KudiNetworkException([super.message = 'No internet connection.']);
}

/// Request timed out — server did not respond within the deadline.
class KudiTimeoutException extends KudiException {
  const KudiTimeoutException(
      [super.message = 'Request timed out. Please try again.']);
}

/// 401/403 — session expired or insufficient permissions.
class KudiUnauthorizedException extends KudiException {
  const KudiUnauthorizedException(
      [super.message = 'Session expired. Please log in again.']);
}

/// 5xx — server-side failure.
class KudiServerException extends KudiException {
  final int? statusCode;
  const KudiServerException(super.message, [this.statusCode]);
}

/// Any other API error (4xx, unexpected response, parse failure, etc.).
class KudiApiException extends KudiException {
  final int? statusCode;
  const KudiApiException(super.message, [this.statusCode]);
}

/// Local storage read/write failure.
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
