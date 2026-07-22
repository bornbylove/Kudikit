// lib/core/extension/string_extension.dart
// ─────────────────────────────────────────────────────────────────────────────
// Convenience extensions on String. Add app-wide string helpers here.
// ─────────────────────────────────────────────────────────────────────────────

extension StringExtension on String {
  /// Returns the string with its first character upper-cased.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Basic email-shape validation (not RFC-exhaustive).
  bool get isValidEmail =>
      RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$').hasMatch(this);
}
