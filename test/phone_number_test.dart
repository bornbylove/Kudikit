// test/phone_number_test.dart
//
// The expected E.164 output is pinned against the backend's regex
// ^\+234[7-9][0-1][0-9]{8}$ and against a number confirmed working via a live
// 200 from POST /api/v1/auth/send-otp.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/core/utils/phone_number.dart';

void main() {
  group('accepted input shapes all normalise to the same number', () {
    const expected = '+2347015697383';

    test('local form with leading zero', () {
      expect(normalizeNigerianPhone('07015697383'), expected);
    });

    test('subscriber form without leading zero', () {
      expect(normalizeNigerianPhone('7015697383'), expected);
    });

    test('already E.164', () {
      expect(normalizeNigerianPhone('+2347015697383'), expected);
    });

    test('country code without plus', () {
      expect(normalizeNigerianPhone('2347015697383'), expected);
    });

    test('spaces, dashes and parens are ignored', () {
      expect(normalizeNigerianPhone('0701 569 7383'), expected);
      expect(normalizeNigerianPhone('0701-569-7383'), expected);
      expect(normalizeNigerianPhone('+234 (701) 569-7383'), expected);
    });
  });

  group('rejects invalid input', () {
    test('too short', () {
      expect(normalizeNigerianPhone('0701569738'), isNull);
      expect(normalizeNigerianPhone('701569738'), isNull);
    });

    test('too long', () {
      expect(normalizeNigerianPhone('070156973830'), isNull);
    });

    test('invalid network prefix', () {
      // Must start [7-9] then [0-1]; 6 and 2 are outside that range.
      expect(normalizeNigerianPhone('06015697383'), isNull);
      expect(normalizeNigerianPhone('07215697383'), isNull);
    });

    test('non-numeric input', () {
      expect(normalizeNigerianPhone('not a phone'), isNull);
      expect(normalizeNigerianPhone(''), isNull);
    });
  });

  group('output always satisfies the backend regex', () {
    test('every accepted form matches the server pattern', () {
      const inputs = [
        '07015697383',
        '7015697383',
        '+2347015697383',
        '2347015697383',
        '0803 123 4567',
        '09015697383',
      ];
      for (final input in inputs) {
        final normalized = normalizeNigerianPhone(input);
        expect(normalized, isNotNull, reason: input);
        expect(nigerianE164Pattern.hasMatch(normalized!), isTrue,
            reason: '$input -> $normalized');
      }
    });
  });

  group('looksLikeNigerianPhone', () {
    // Decides whether a single "email or phone" field is sent as phoneNumber
    // or email — the OTP endpoints take them as separate fields.
    test('accepts every phone shape', () {
      for (final input in [
        '07015697383',
        '7015697383',
        '+2347015697383',
        '2347015697383',
        '0701 569 7383',
      ]) {
        expect(looksLikeNigerianPhone(input), isTrue, reason: input);
      }
    });

    test('rejects emails', () {
      for (final input in [
        'user@example.com',
        'abrahamchidubem@gmail.com',
        '07015697383@example.com',
      ]) {
        expect(looksLikeNigerianPhone(input), isFalse, reason: input);
      }
    });

    test('rejects anything that is neither', () {
      expect(looksLikeNigerianPhone(''), isFalse);
      expect(looksLikeNigerianPhone('not a phone'), isFalse);
      expect(looksLikeNigerianPhone('12345'), isFalse);
    });
  });

  group('nigerianPhoneError', () {
    test('returns null for a valid number', () {
      expect(nigerianPhoneError('07015697383'), isNull);
    });

    test('prompts when empty', () {
      expect(nigerianPhoneError('   '), 'Please enter your phone number');
    });

    test('explains when invalid', () {
      expect(nigerianPhoneError('123'), contains('valid Nigerian'));
    });
  });
}
