// lib/services/identity/dojah_exceptions.dart
//
// Typed errors for the Dojah identity-verification integration. Deliberately
// separate from KudiXxxException (lib/config/dio_client.dart) — Dojah is a
// distinct third-party API called over its own Dio instance, not the Kudikit
// gateway/auth backend, and its error shapes (402 = insufficient wallet
// balance, for example) don't map cleanly onto the Kudikit exception set.
//
// None of these may ever carry the Dojah secret key, a stack trace, or a raw
// API response body in their message — messages here are what the UI is
// allowed to show, or close to it.

abstract class DojahException implements Exception {
  final String message;
  const DojahException(this.message);
  @override
  String toString() => message;
}

/// DOJAH_APP_ID / DOJAH_SECRET_KEY are missing at build time. Thrown before
/// any network call is made — never a request that finds out this way.
class DojahNotConfiguredException extends DojahException {
  const DojahNotConfiguredException()
      : super('Identity verification is not available right now.');
}

class DojahInvalidImageException extends DojahException {
  const DojahInvalidImageException([
    super.message = 'We couldn\'t process that photo. Please try again.',
  ]);
}

class DojahUnauthorizedException extends DojahException {
  const DojahUnauthorizedException()
      : super('Identity verification is not available right now.');
}

/// HTTP 402 — Dojah account has insufficient wallet balance to run the
/// check. Not something the end user can fix; treat as a service outage.
class DojahInsufficientBalanceException extends DojahException {
  const DojahInsufficientBalanceException()
      : super('Identity verification is temporarily unavailable.');
}

class DojahRateLimitedException extends DojahException {
  const DojahRateLimitedException()
      : super('Too many attempts. Please wait a moment and try again.');
}

class DojahNetworkException extends DojahException {
  const DojahNetworkException([
    super.message = 'No internet connection. Please try again.',
  ]);
}

class DojahTimeoutException extends DojahException {
  const DojahTimeoutException()
      : super('The request timed out. Please try again.');
}

class DojahServerException extends DojahException {
  const DojahServerException()
      : super('Something went wrong on our end. Please try again later.');
}

/// Response came back 2xx but wasn't shaped like a liveness response.
class DojahMalformedResponseException extends DojahException {
  const DojahMalformedResponseException()
      : super('We couldn\'t read the verification result. Please try again.');
}

class DojahUnknownException extends DojahException {
  const DojahUnknownException()
      : super('Something went wrong. Please try again.');
}
