// lib/core/network/api_reponse.dart
// ─────────────────────────────────────────────────────────────────────────────
// Generic wrapper describing the outcome of an API call.
//
// NOTE: the filename keeps the spelling from the agreed target ("api_reponse");
// it looks like a typo for "api_response" — rename if desired.
// ─────────────────────────────────────────────────────────────────────────────

/// A generic success/failure envelope around an API result.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) =>
      ApiResponse(
        success: true,
        data: data,
        message: message,
        statusCode: statusCode,
      );

  factory ApiResponse.failure(String message, {int? statusCode}) =>
      ApiResponse(
        success: false,
        message: message,
        statusCode: statusCode,
      );
}
