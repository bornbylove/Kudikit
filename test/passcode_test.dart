// test/passcode_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/core/utils/passcode.dart';

void main() {
  group('isValidPasscode', () {
    test('accepts exactly 6 digits', () {
      expect(isValidPasscode('123456'), isTrue);
      expect(isValidPasscode('000000'), isTrue);
      expect(isValidPasscode('999999'), isTrue);
    });

    test('rejects wrong lengths', () {
      expect(isValidPasscode('12345'), isFalse);
      expect(isValidPasscode('1234567'), isFalse);
      expect(isValidPasscode(''), isFalse);
    });

    test('rejects non-digits — this is the whole point of the change', () {
      expect(isValidPasscode('Abc@123'), isFalse);
      expect(isValidPasscode('12345a'), isFalse);
      expect(isValidPasscode('12 456'), isFalse);
      expect(isValidPasscode('12-456'), isFalse);
    });

    test('rejects the old alphanumeric format outright', () {
      // Would have passed the previous 8–12 char upper/lower/number/special
      // rule; must not pass now.
      expect(isValidPasscode('Passw0rd!'), isFalse);
    });

    test('length constant and pattern stay in agreement', () {
      expect(isValidPasscode('1' * kPasscodeLength), isTrue);
      expect(isValidPasscode('1' * (kPasscodeLength - 1)), isFalse);
      expect(isValidPasscode('1' * (kPasscodeLength + 1)), isFalse);
    });
  });

  group('passcodeError', () {
    test('null for a valid passcode', () {
      expect(passcodeError('123456'), isNull);
    });

    test('prompts when empty', () {
      expect(passcodeError('  '), contains('Enter your'));
    });

    test('states the digit rule when malformed', () {
      expect(passcodeError('12ab56'), contains('exactly 6 digits'));
      expect(passcodeError('123'), contains('exactly 6 digits'));
    });
  });

  group('confirmPasscodeError', () {
    test('null when the two match', () {
      expect(confirmPasscodeError('123456', '123456'), isNull);
    });

    test('prompts when confirmation is empty', () {
      expect(confirmPasscodeError('123456', ''), contains('Re-enter'));
    });

    test('reports a mismatch', () {
      expect(confirmPasscodeError('123456', '654321'), 'Passcodes do not match');
    });
  });
}
