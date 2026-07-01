import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
// =============================================================================
// TransactionPinService
// -----------------------------------------------------------------------------
// Manages the 4-digit transaction PIN used to validate all payments.
// Stored separately from the login passcode using a distinct secure key.
// Hashing: PBKDF2-like salted SHA-256 repeated 1000× (matches StorageService).
// =============================================================================

class TransactionPinException implements Exception {
  final String message;
  TransactionPinException(this.message);
  @override
  String toString() => message;
}

class TransactionPinService {
  TransactionPinService._();
  static final TransactionPinService instance = TransactionPinService._();
  factory TransactionPinService() => instance;

  static const String _txPinKey = 'kudipay_transaction_pin_v1';
  static const int _pinLength = 4;
  static const int _hashIterations = 1000;

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ---------------------------------------------------------------------------
  // Save transaction PIN (hashed)
  // ---------------------------------------------------------------------------
  Future<void> saveTransactionPin(String pin) async {
    if (pin.length != _pinLength || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw TransactionPinException(
          'Transaction PIN must be exactly 4 digits.');
    }
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(
        key: _txPinKey, value: '$salt:$hash:$_hashIterations');
  }

  // ---------------------------------------------------------------------------
  // Verify transaction PIN
  // ---------------------------------------------------------------------------
  Future<bool> verifyTransactionPin(String pin) async {
    final data = await _getStoredPinData();
    if (data == null) return false;
    final expectedHash = _hashPin(pin, data['salt']!);
    return _constantTimeCompare(expectedHash, data['hash']!);
  }

  // ---------------------------------------------------------------------------
  // Check if a transaction PIN has been set
  // ---------------------------------------------------------------------------
  Future<bool> hasTransactionPin() async {
    final data = await _getStoredPinData();
    return data != null;
  }

  // ---------------------------------------------------------------------------
  // Delete transaction PIN
  // ---------------------------------------------------------------------------
  Future<void> deleteTransactionPin() async {
    await _secureStorage.delete(key: _txPinKey);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    Uint8List bytes = Uint8List.fromList(utf8.encode('$salt:$pin'));
    for (var i = 0; i < _hashIterations; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64Url.encode(bytes);
  }

  Future<Map<String, String>?> _getStoredPinData() async {
    try {
      final stored = await _secureStorage.read(key: _txPinKey);
      if (stored == null) return null;
      final parts = stored.split(':');
      if (parts.length != 3) return null;
      return {'salt': parts[0], 'hash': parts[1]};
    } catch (_) {
      return null;
    }
  }

  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
