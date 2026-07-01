import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// storage_service_pin_test.dart
// -----------------------------------------------------------------------------
// UPDATED: All tests now reflect the new alphanumeric passcode rules:
//   - 8 to 12 characters
//   - At least one uppercase letter
//   - At least one lowercase letter
//   - At least one number
//   - At least one special character: ! @ # $ % ^ & *
//
// Storage key changed from 'user_pin' → 'user_passcode' to match
// the _userPasscodeKey constant in storage_services.dart.
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  // ---------------------------------------------------------------------------
  // Valid test passcodes — meet ALL complexity rules
  // ---------------------------------------------------------------------------
  const validPasscode1 = 'Secret1!';      // 8 chars — minimum valid
  const validPasscode2 = 'MyPass1@2024';  // 12 chars — maximum valid
  const validPasscode3 = 'Hello\$99';     // 8 chars — alternate special char

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService.instance;
    // Always start each test with a clean slate
    await storageService.deletePasscode();
  });

  // ===========================================================================
  // GROUP 1 — Core Passcode Hashing Security
  // ===========================================================================

  group('Passcode Hashing Security Tests', () {
    test('Should hash passcode instead of storing plaintext', () async {
      await storageService.savePasscode(validPasscode1);

      const secureStorage = FlutterSecureStorage();
      // FIX: key changed from 'user_pin' → 'user_passcode'
      final storedValue = await secureStorage.read(key: 'user_passcode');

      // Verify it is NOT the plaintext passcode
      expect(storedValue, isNot(equals(validPasscode1)));

      // Verify it contains salt:hash:iterations format
      expect(storedValue, contains(':'));
      final parts = storedValue!.split(':');
      expect(parts.length, equals(3));
    });

    test('Should verify correct passcode successfully', () async {
      await storageService.savePasscode(validPasscode1);
      final isValid = await storageService.verifyPasscode(validPasscode1);
      expect(isValid, isTrue);
    });

    test('Should reject incorrect passcode', () async {
      await storageService.savePasscode(validPasscode1);
      final isValid = await storageService.verifyPasscode('WrongPass1!');
      expect(isValid, isFalse);
    });

    test('Should generate different hashes for same passcode (different salts)', () async {
      await storageService.savePasscode(validPasscode1);
      const secureStorage = FlutterSecureStorage();
      final firstHash = await secureStorage.read(key: 'user_passcode');

      await storageService.deletePasscode();
      await storageService.savePasscode(validPasscode1);
      final secondHash = await secureStorage.read(key: 'user_passcode');

      // Hashes should be different due to different random salts
      expect(firstHash, isNot(equals(secondHash)));

      // But verification should still work
      expect(await storageService.verifyPasscode(validPasscode1), isTrue);
    });

    test('Alias savePin() should work the same as savePasscode()', () async {
      // savePin is kept for backwards compatibility — must behave identically
      await storageService.savePin(validPasscode1);
      expect(await storageService.verifyPin(validPasscode1), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 2 — Passcode Validation Rules (NEW ALPHANUMERIC RULES)
  // ===========================================================================

  group('Passcode Validation Rules', () {
    // ── Length rules ──────────────────────────────────────────────────────────

    test('Should reject passcode shorter than 8 characters', () async {
      // 'Sec1!' is only 5 chars — too short
      expect(
        () => storageService.savePasscode('Sec1!'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject passcode longer than 12 characters', () async {
      // 13 chars — too long
      expect(
        () => storageService.savePasscode('MyLongPass1!X'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should accept 8-character passcode (minimum)', () async {
      await storageService.savePasscode(validPasscode1); // 'Secret1!'
      expect(await storageService.verifyPasscode(validPasscode1), isTrue);
    });

    test('Should accept 12-character passcode (maximum)', () async {
      await storageService.savePasscode(validPasscode2); // 'MyPass1@2024'
      expect(await storageService.verifyPasscode(validPasscode2), isTrue);
    });

    // ── Character type rules ──────────────────────────────────────────────────

    test('Should reject passcode with no uppercase letter', () async {
      // 'secret1!' — all lowercase, missing uppercase
      expect(
        () => storageService.savePasscode('secret1!'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject passcode with no lowercase letter', () async {
      // 'SECRET1!' — all uppercase, missing lowercase
      expect(
        () => storageService.savePasscode('SECRET1!'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject passcode with no number', () async {
      // 'SecretAA!' — no digit
      expect(
        () => storageService.savePasscode('SecretAA!'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject passcode with no special character', () async {
      // 'Secret1234' — no special char
      expect(
        () => storageService.savePasscode('Secret1234'),
        throwsA(isA<StorageException>()),
      );
    });

    // ── OLD TESTS REMOVED — these were wrong and must not exist ──────────────
    // REMOVED: 'Should reject non-numeric PIN' — alphanumeric is now REQUIRED
    // REMOVED: 'Should reject PIN shorter than 4 digits' — min is now 8 chars
    // REMOVED: 'Should reject PIN longer than 6 digits' — max is now 12 chars
    // REMOVED: 'Should accept 4-digit PIN' — '1234' now FAILS validation
    // REMOVED: 'Should accept 6-digit PIN' — '123456' now FAILS validation

    test('Should accept valid passcode with all special chars in allowed set', () async {
      // Test each allowed special character
      final specialChars = ['!', '@', '#', r'$', '%', '^', '&', '*'];
      for (final char in specialChars) {
        await storageService.deletePasscode();
        final passcode = 'Secret1$char';
        await storageService.savePasscode(passcode);
        expect(await storageService.verifyPasscode(passcode), isTrue,
            reason: 'Should accept special char: $char');
      }
    });

    test('Should handle empty passcode gracefully', () async {
      expect(
        () => storageService.savePasscode(''),
        throwsA(isA<StorageException>()),
      );
    });
  });

  // ===========================================================================
  // GROUP 3 — hasPasscode / deletePasscode
  // ===========================================================================

  group('hasPasscode and deletePasscode', () {
    test('hasPasscode should return false when no passcode is stored', () async {
      expect(await storageService.hasPasscode(), isFalse);
    });

    test('hasPasscode should return true when passcode is stored', () async {
      await storageService.savePasscode(validPasscode1);
      expect(await storageService.hasPasscode(), isTrue);
    });

    test('deletePasscode should remove stored passcode', () async {
      await storageService.savePasscode(validPasscode1);
      expect(await storageService.hasPasscode(), isTrue);

      await storageService.deletePasscode();
      expect(await storageService.hasPasscode(), isFalse);
    });

    // Alias tests
    test('hasPin alias should work correctly', () async {
      await storageService.savePin(validPasscode1);
      expect(await storageService.hasPin(), isTrue);
      await storageService.deletePin();
      expect(await storageService.hasPin(), isFalse);
    });
  });

  // ===========================================================================
  // GROUP 4 — changePasscode
  // ===========================================================================

  group('changePasscode', () {
    test('Should change passcode with correct old passcode', () async {
      await storageService.savePasscode(validPasscode1);

      final changed = await storageService.changePasscode(
        oldPasscode: validPasscode1,
        newPasscode: validPasscode2,
      );

      expect(changed, isTrue);
      expect(await storageService.verifyPasscode(validPasscode2), isTrue);
      expect(await storageService.verifyPasscode(validPasscode1), isFalse);
    });

    test('Should fail changePasscode with incorrect old passcode', () async {
      await storageService.savePasscode(validPasscode1);

      final changed = await storageService.changePasscode(
        oldPasscode: 'WrongOld1!',
        newPasscode: validPasscode2,
      );

      expect(changed, isFalse);
      // Old passcode must still be valid
      expect(await storageService.verifyPasscode(validPasscode1), isTrue);
    });

    test('changePin alias should work the same as changePasscode', () async {
      await storageService.savePin(validPasscode1);

      final changed = await storageService.changePin(
        oldPin: validPasscode1,
        newPin: validPasscode2,
      );

      expect(changed, isTrue);
      expect(await storageService.verifyPin(validPasscode2), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 5 — Security Strength
  // ===========================================================================

  group('Passcode Security Strength Tests', () {
    test('Should use PBKDF2 with at least 10,000 iterations', () async {
      await storageService.savePasscode(validPasscode1);

      const secureStorage = FlutterSecureStorage();
      // FIX: key changed from 'user_pin' → 'user_passcode'
      final storedValue = await secureStorage.read(key: 'user_passcode');
      final parts = storedValue!.split(':');

      final iterations = int.parse(parts[2]);
      expect(iterations, greaterThanOrEqualTo(10000));
    });

    test('Salt should be unique on every save', () async {
      final salts = <String>{};
      for (var i = 0; i < 10; i++) {
        await storageService.deletePasscode();
        await storageService.savePasscode(validPasscode1);

        const secureStorage = FlutterSecureStorage();
        final storedValue = await secureStorage.read(key: 'user_passcode');
        final salt = storedValue!.split(':')[0];
        salts.add(salt);
      }

      // Every salt must be unique
      expect(salts.length, equals(10));
    });

    test('Hash output should be consistent — verify returns true repeatedly', () async {
      await storageService.savePasscode(validPasscode1);

      for (var i = 0; i < 5; i++) {
        expect(await storageService.verifyPasscode(validPasscode1), isTrue);
      }
    });

    test('Should resist timing attacks via constant-time comparison', () async {
      await storageService.savePasscode(validPasscode1);

      final stopwatch1 = Stopwatch()..start();
      await storageService.verifyPasscode('WrongA1!');  // Differs early
      stopwatch1.stop();

      final stopwatch2 = Stopwatch()..start();
      await storageService.verifyPasscode('Secret1?');  // Differs late
      stopwatch2.stop();

      final timeDiff = (stopwatch1.elapsedMicroseconds - stopwatch2.elapsedMicroseconds).abs();
      expect(timeDiff, lessThan(10000)); // 10ms tolerance
    });
  });

  // ===========================================================================
  // GROUP 6 — Edge Cases & Corrupted Storage
  // ===========================================================================

  group('Edge Cases and Migration', () {
    test('Should handle corrupted storage gracefully', () async {
      const secureStorage = FlutterSecureStorage();
      // Manually write invalid data to the correct key
      await secureStorage.write(key: 'user_passcode', value: 'corrupted_data');

      // Verification should return false, not throw
      expect(await storageService.verifyPasscode(validPasscode1), isFalse);
      expect(await storageService.hasPasscode(), isFalse);
    });

    test('Should handle missing storage gracefully', () async {
      await storageService.deletePasscode();
      expect(await storageService.verifyPasscode(validPasscode1), isFalse);
    });
  });
}