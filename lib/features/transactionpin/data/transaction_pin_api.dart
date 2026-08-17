// lib/features/transactionpin/data/transaction_pin_api.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// NOT YET ACTIVE — the backend endpoints do not exist.
// ─────────────────────────────────────────────────────────────────────────────
//
// Confirmed against GET /v3/api-docs: the spec contains no path and no schema
// matching "pin". Until that changes, the transaction PIN lives ONLY in
// device secure storage (see TransactionPinService), which means:
//
//   * reinstalling the app lets anyone set a fresh PIN and authorise transfers
//   * the local check is client-side, so it is bypassable on a rooted device
//
// That is not adequate for the factor that authorises moving money, so this
// file exists ready to switch on.
//
// TO ACTIVATE, once the endpoints ship:
//   1. Set kTransactionPinServerSyncEnabled = true below.
//   2. Confirm the three path constants and the request/response field names
//      against the updated spec — the shapes here are a PROPOSAL, modelled on
//      the conventions the auth endpoints already use, not something the
//      backend has agreed.
//   3. Drop the local-only fallbacks in TransactionPinService.
//
// The code is written as real, compiled Dart rather than commented out so the
// analyser keeps it honest and it cannot quietly rot.

import 'package:kudipay/core/network/api_client.dart';

/// Master switch. While false, nothing in this class is called and the PIN
/// stays device-local.
const bool kTransactionPinServerSyncEnabled = false;

/// PROPOSED paths — verify before enabling.
const String kSetTransactionPinPath = '/auth/transaction-pin';
const String kVerifyTransactionPinPath = '/auth/transaction-pin/verify';
const String kChangeTransactionPinPath = '/auth/transaction-pin/change';

class TransactionPinApi {
  final DioClient _client;

  const TransactionPinApi(this._client);

  /// Registers [pin] against the authenticated user.
  ///
  /// The PIN is sent in plaintext over TLS and hashed server-side, the same
  /// way the login passcode is handled — the client must NOT pre-hash it, or
  /// the server could never verify a PIN entered on a different device.
  Future<void> setPin(String pin) async {
    try {
      await _client.post<Map<String, dynamic>>(
        kSetTransactionPinPath,
        data: {'pin': pin, 'confirmPin': pin},
      );
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Could not save your transaction PIN: $e');
    }
  }

  /// Asks the server whether [pin] is correct.
  ///
  /// This is the check that matters — the local one in TransactionPinService
  /// is only a convenience so the UI can fail fast while offline.
  Future<bool> verifyPin(String pin) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        kVerifyTransactionPinPath,
        data: {'pin': pin},
      );
      final data = res.data?['data'];
      if (data is Map<String, dynamic>) {
        return data['valid'] == true || data['verified'] == true;
      }
      return res.data?['status'] == 'success';
    } on KudiUnauthorizedException {
      // Wrong PIN, as opposed to a transport failure.
      return false;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Could not verify your transaction PIN: $e');
    }
  }

  /// Replaces an existing PIN. Requires the current one, so a stolen unlocked
  /// handset cannot silently rotate it.
  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        kChangeTransactionPinPath,
        data: {
          'currentPin': currentPin,
          'newPin': newPin,
          'confirmPin': newPin,
        },
      );
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Could not change your transaction PIN: $e');
    }
  }
}
