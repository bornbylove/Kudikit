// lib/core/utils/phone_number.dart
//
// Nigerian phone number normalisation and validation.
//
// Ported from origin/dev (lib/core/utils/phone_number.dart).
//
// The backend requires E.164 and enforces it with:
//   ^\+234[7-9][0-1][0-9]{8}$
// (RegisterRequest.phoneNumber / SendOtpRequest.phoneNumber in
// kudikit_auth_service). Its lookups (login, OTP) are an EXACT match on that
// stored form, so every phone sent to the server must go through
// [normalizeNigerianPhone] first.
//
// Users type numbers in several shapes — 07015697383, 7015697383,
// +2347015697383, 234 701 569 7383 — all of which mean the same number.
// Normalise on input rather than forcing one format on the user.

/// The subscriber part: 10 digits, no national prefix. e.g. 7015697383
final RegExp _subscriberPattern = RegExp(r'^[7-9][0-1]\d{8}$');

/// The full E.164 form the backend accepts.
final RegExp nigerianE164Pattern = RegExp(r'^\+234[7-9][0-1]\d{8}$');

/// Converts any accepted local form to E.164 (`+234…`), or returns null when
/// the input is not a valid Nigerian mobile number.
///
///   '07015697383'    -> '+2347015697383'
///   '7015697383'     -> '+2347015697383'
///   '+234 701 569 7383' -> '+2347015697383'
///   '0701569738'     -> null  (too short)
String? normalizeNigerianPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s()\-.]'), '');

  // Strip whichever national/international prefix is present. Order matters:
  // '+234' and '234' must be checked before the local '0'.
  if (digits.startsWith('+234')) {
    digits = digits.substring(4);
  } else if (digits.startsWith('234')) {
    digits = digits.substring(3);
  } else if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  if (!_subscriberPattern.hasMatch(digits)) return null;
  return '+234$digits';
}

/// A user-facing validation message, or null when [raw] is a valid number.
///
/// The invalid-number wording is the PRD's registration message (and the
/// backend's own) so the client and server never disagree on it.
String? nigerianPhoneError(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Please enter your phone number';
  if (normalizeNigerianPhone(trimmed) == null) {
    return 'Invalid Nigerian mobile number';
  }
  return null;
}
