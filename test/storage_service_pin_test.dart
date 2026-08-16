import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// storage_service_pin_test.dart
// -----------------------------------------------------------------------------
// Passcode rules per the PRD's Passcode Security Rules (Registration Screen
// §8, confirmed 2026-08-10):
//   a. Length: 6-8 numeric digits only
//   b. Prohibited patterns:
//      i.   Sequential (123456, 456789)
//      ii.  Repetitive (111111, 222222)
//      iii. Phone number segments (last 6 digits of entered phone)
//      iv.  Common PINs (a curated subset here — see StorageService's doc
//           comment on why this isn't a real 10,000-entry breach dataset)
//      v.   Date patterns (DDMMYY, MMDDYY)
//
// `FlutterSecureStorage` has no in-memory test backend by default and
// otherwise throws MissingPluginException under `flutter test` — these tests
// install a fake method-channel handler backed by a plain Map so the real
// StorageService code path (including its actual encoding) runs
// deterministically without touching a device/simulator.
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> secureBackingStore;

  late StorageService storageService;

  // ── Valid test passcodes — meet ALL current rules ──────────────────────
  const validPasscode1 = '284915'; // 6 digits — minimum valid
  const validPasscode2 = '48293176'; // 8 digits — maximum valid
  const validPasscode3 = '204837'; // 6 digits — distinct alternate

  setUpAll(() {
    secureBackingStore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (MethodCall call) async {
      switch (call.method) {
        case 'write':
          final args = call.arguments as Map;
          secureBackingStore[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          final args = call.arguments as Map;
          return secureBackingStore[args['key'] as String];
        case 'delete':
          final args = call.arguments as Map;
          secureBackingStore.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          secureBackingStore.clear();
          return null;
        case 'readAll':
          return secureBackingStore;
        case 'containsKey':
          final args = call.arguments as Map;
          return secureBackingStore.containsKey(args['key'] as String);
        default:
          return null;
      }
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureBackingStore.clear();
    storageService = StorageService.instance;
  });

  // ===========================================================================
  // GROUP 1 — Core Passcode Hashing Security
  // ===========================================================================

  group('Passcode Hashing Security Tests', () {
    test('Should hash passcode instead of storing plaintext', () async {
      await storageService.savePasscode(validPasscode1);

      const secureStorage = FlutterSecureStorage();
      final storedValue = await secureStorage.read(key: 'user_passcode');

      expect(storedValue, isNot(equals(validPasscode1)));
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
      final isValid = await storageService.verifyPasscode('960273');
      expect(isValid, isFalse);
    });

    test('Should generate different hashes for same passcode (different salts)', () async {
      await storageService.savePasscode(validPasscode1);
      const secureStorage = FlutterSecureStorage();
      final firstHash = await secureStorage.read(key: 'user_passcode');

      await storageService.deletePasscode();
      await storageService.savePasscode(validPasscode1);
      final secondHash = await secureStorage.read(key: 'user_passcode');

      expect(firstHash, isNot(equals(secondHash)));
      expect(await storageService.verifyPasscode(validPasscode1), isTrue);
    });

    test('Alias savePin() should work the same as savePasscode()', () async {
      await storageService.savePin(validPasscode1);
      expect(await storageService.verifyPin(validPasscode1), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 2 — Passcode Validation Rules (6-8 numeric digits, PRD §8)
  // ===========================================================================

  group('Passcode Validation Rules', () {
    // ── Length / format rules ──────────────────────────────────────────────

    test('Should reject passcode shorter than 6 digits', () async {
      expect(
        () => storageService.savePasscode('2849'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject passcode longer than 8 digits', () async {
      expect(
        () => storageService.savePasscode('482931765'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should accept 6-digit passcode (minimum)', () async {
      await storageService.savePasscode(validPasscode1);
      expect(await storageService.verifyPasscode(validPasscode1), isTrue);
    });

    test('Should accept 8-digit passcode (maximum)', () async {
      await storageService.savePasscode(validPasscode2);
      expect(await storageService.verifyPasscode(validPasscode2), isTrue);
    });

    test('Should reject a non-numeric passcode', () async {
      expect(
        () => storageService.savePasscode('Secret1!'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a passcode containing any letter', () async {
      expect(
        () => storageService.savePasscode('12345a'),
        throwsA(isA<StorageException>()),
      );
    });

    // ── Pattern rules ──────────────────────────────────────────────────────

    test('Should reject an ascending sequential passcode', () async {
      expect(
        () => storageService.savePasscode('456789'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a descending sequential passcode', () async {
      expect(
        () => storageService.savePasscode('987654'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a repetitive passcode', () async {
      expect(
        () => storageService.savePasscode('222222'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a common passcode', () async {
      expect(
        () => storageService.savePasscode('123456'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a date-pattern passcode (DDMMYY)', () async {
      // 15 03 26 -> day 15, month 03: a plausible DDMMYY date.
      expect(
        () => storageService.savePasscode('150326'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject a date-pattern passcode (MMDDYY)', () async {
      // 03 15 26 -> month 03, day 15: a plausible MMDDYY date (fails the
      // DDMMYY interpretation since 15 isn't a valid month, but passes the
      // MMDDYY one).
      expect(
        () => storageService.savePasscode('031526'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Date-pattern rule only applies to 6-digit passcodes', () async {
      // '15032026' is 8 digits; not evaluated as a date, and otherwise
      // satisfies every other rule.
      await storageService.savePasscode('15032026');
      expect(await storageService.verifyPasscode('15032026'), isTrue);
    });

    test('Should reject a passcode derived from the phone number', () async {
      // '482931' is non-sequential, non-repetitive, not on the common list,
      // and not a plausible date (48 is not a valid day/month) — it would
      // otherwise be a perfectly valid passcode, but it exactly matches the
      // last 6 digits of the phone number below.
      expect(
        () => storageService.savePasscode('482931', phoneNumber: '+2348482931'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should accept a passcode when no phone number is supplied', () async {
      await storageService.savePasscode(validPasscode3);
      expect(await storageService.verifyPasscode(validPasscode3), isTrue);
    });

    test('Should handle empty passcode gracefully', () async {
      expect(
        () => storageService.savePasscode(''),
        throwsA(isA<StorageException>()),
      );
    });

    test('passcodeValidationError returns null for a valid passcode', () {
      expect(storageService.passcodeValidationError(validPasscode1), isNull);
    });

    test('passcodeValidationError returns a message for an invalid passcode', () {
      expect(storageService.passcodeValidationError('123456'), isNotNull);
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
        oldPasscode: '960273',
        newPasscode: validPasscode2,
      );

      expect(changed, isFalse);
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
      await storageService.verifyPasscode('960273'); // Differs early
      stopwatch1.stop();

      final stopwatch2 = Stopwatch()..start();
      await storageService.verifyPasscode('284916'); // Differs late
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
      await secureStorage.write(key: 'user_passcode', value: 'corrupted_data');

      expect(await storageService.verifyPasscode(validPasscode1), isFalse);
      expect(await storageService.hasPasscode(), isFalse);
    });

    test('Should handle missing storage gracefully', () async {
      await storageService.deletePasscode();
      expect(await storageService.verifyPasscode(validPasscode1), isFalse);
    });
  });
}
