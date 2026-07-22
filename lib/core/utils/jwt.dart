// lib/core/utils/jwt.dart
// ─────────────────────────────────────────────────────────────────────────────
// Minimal, dependency-free JWT helpers (base64url-decode the payload).
// Does NOT verify the signature — for reading claims (e.g. `exp`) only.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

/// Static helpers for reading (not verifying) JSON Web Tokens.
class Jwt {
  const Jwt._();

  /// Decodes the JWT payload (middle segment) into a claims map.
  /// Throws [FormatException] if the token is malformed.
  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException(
          'Invalid JWT: expected 3 dot-separated segments.');
    }
    final decoded = json.decode(_decodeBase64Url(parts[1]));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JWT payload.');
    }
    return decoded;
  }

  /// Returns the token's expiry (`exp` claim) as UTC, or null if absent.
  static DateTime? expiry(String token) {
    final exp = decodePayload(token)['exp'];
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  /// True if the token carries an `exp` claim that is in the past.
  /// Returns false when there is no `exp` claim.
  static bool isExpired(String token) {
    final exp = expiry(token);
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(exp);
  }

  static String _decodeBase64Url(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw const FormatException('Invalid base64url segment in JWT.');
    }
    return utf8.decode(base64.decode(output));
  }
}
