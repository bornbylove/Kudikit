// lib/core/network/api_envelope.dart
//
// Every endpoint on the auth/KYC service wraps its payload:
//
//   { "status": "success", "message": "...", "errorCode": null, "data": { ... } }
//
// `status`, `message` and `errorCode` stay at the top level; the useful body is
// always under `data`. These helpers unwrap that consistently.
//
// NOTE: AuthRepositoryImpl still carries its own private `_payload` predating
// this file. Both behave identically — that one can be swapped for this.

/// Returns the enveloped `data` object, falling back to [res] itself so a
/// response that is not enveloped still works.
Map<String, dynamic> unwrapPayload(Map<String, dynamic> res) {
  final data = res['data'];
  return data is Map<String, dynamic> ? data : res;
}

/// True when the envelope reports success.
bool isEnvelopeSuccess(Map<String, dynamic> res) =>
    res['status'] == 'success' || res['success'] == true;

/// The server-supplied error message, if any.
String? envelopeMessage(Map<String, dynamic> res) => res['message'] as String?;
