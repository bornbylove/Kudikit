// lib/core/utils/passcode.dart
//
// Single source of truth for the sign-in passcode format.
//
// The backend does not constrain it — RegisterRequest.passcode and
// LoginRequest.passcode are both `string, minLength: 1` — so every rule here
// is client-side. It previously lived duplicated across signup.dart,
// reset_passcode.dart, login_page.dart, constant.dart and StorageService,
// which is how those five copies drifted apart. Change the format here only.
//
// NOTE: this is the *sign-in* passcode, distinct from the 4-digit transaction
// PIN (TransactionPinService) and from the 6-digit OTP code.

/// Number of digits in a sign-in passcode.
const int kPasscodeLength = 6;

final RegExp _passcodePattern = RegExp('^\\d{$kPasscodeLength}\$');

/// True when [value] is exactly [kPasscodeLength] digits.
bool isValidPasscode(String value) => _passcodePattern.hasMatch(value.trim());

/// A user-facing validation message, or null when [value] is acceptable.
String? passcodeError(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Enter your $kPasscodeLength-digit passcode';
  if (!isValidPasscode(trimmed)) {
    return 'Passcode must be exactly $kPasscodeLength digits';
  }
  return null;
}

/// Validation message for the confirmation entry, or null when it matches.
String? confirmPasscodeError(String passcode, String confirmation) {
  if (confirmation.isEmpty) return 'Re-enter your passcode to confirm';
  if (confirmation != passcode) return 'Passcodes do not match';
  return null;
}
