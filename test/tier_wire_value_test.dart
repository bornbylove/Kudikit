// test/tier_wire_value_test.dart
//
// Pins the tier enum against components.schemas.SelectTierRequest, whose only
// accepted values are BASIC | PRO | MEGA.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/features/auth/data/auth_services.dart';

void main() {
  group('tierWireValue', () {
    test('maps the three tier numbers to the server enum', () {
      expect(tierWireValue(1), 'BASIC');
      expect(tierWireValue(2), 'PRO');
      expect(tierWireValue(3), 'MEGA');
    });

    test('only ever emits values the schema accepts', () {
      const accepted = {'BASIC', 'PRO', 'MEGA'};
      for (var n = 1; n <= 3; n++) {
        expect(accepted.contains(tierWireValue(n)), isTrue);
      }
    });

    test('throws rather than silently downgrading an unknown tier', () {
      // A default-to-BASIC would quietly cost a user the tier they picked.
      expect(() => tierWireValue(0), throwsArgumentError);
      expect(() => tierWireValue(4), throwsArgumentError);
      expect(() => tierWireValue(-1), throwsArgumentError);
    });
  });

  group('OtpPurpose', () {
    test('wire values match the backend enum', () {
      expect(OtpPurpose.registration.wire, 'REGISTRATION');
      expect(OtpPurpose.login.wire, 'LOGIN');
      expect(OtpPurpose.forgotPasscode.wire, 'FORGOT_PASSCODE');
      expect(OtpPurpose.deviceLink.wire, 'DEVICE_LINK');
      expect(OtpPurpose.emailChange.wire, 'EMAIL_CHANGE');
    });
  });
}
