// test/kyc_request_builders_test.dart
//
// Pins the wire contract for verify-bvn / verify-nin against /v3/api-docs.
// These field names are the exact thing that was wrong before the audit
// (the old code sent id_number/id_type to a path that did not exist), so they
// are worth asserting literally.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_request_builders.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

void main() {
  group('kycVerifyPathFor', () {
    test('BVN and NIN are distinct endpoints', () {
      expect(kycVerifyPathFor(IdType.bvn), '/auth/kyc/verify-bvn');
      expect(kycVerifyPathFor(IdType.nin), '/auth/kyc/verify-nin');
    });

    test('paths are relative to the /api/v1 base url', () {
      // AppConfig.baseUrl already ends in /api/v1 — a leading /api/v1 here
      // would produce /api/v1/api/v1/... as it did before the audit.
      for (final t in IdType.values) {
        expect(kycVerifyPathFor(t).startsWith('/auth/kyc/'), isTrue);
        expect(kycVerifyPathFor(t).contains('/api/v1'), isFalse);
      }
    });
  });

  group('buildIdentityVerificationBody', () {
    test('BVN uses the bvn key', () {
      final body = buildIdentityVerificationBody(
        idNumber: '12345678901',
        idType: IdType.bvn,
        selfieImageBase64: 'AAAA',
      );
      expect(body, {'bvn': '12345678901', 'selfieImageBase64': 'AAAA'});
    });

    test('NIN uses the nin key', () {
      final body = buildIdentityVerificationBody(
        idNumber: '10987654321',
        idType: IdType.nin,
        selfieImageBase64: 'BBBB',
      );
      expect(body, {'nin': '10987654321', 'selfieImageBase64': 'BBBB'});
    });

    test('never emits the pre-audit field names', () {
      for (final t in IdType.values) {
        final body = buildIdentityVerificationBody(
          idNumber: '12345678901',
          idType: t,
          selfieImageBase64: 'x',
        );
        expect(body.containsKey('id_number'), isFalse);
        expect(body.containsKey('id_type'), isFalse);
        expect(body.containsKey('idNumber'), isFalse);
      }
    });

    test('selfie is always present — it is required by both endpoints', () {
      for (final t in IdType.values) {
        final body = buildIdentityVerificationBody(
          idNumber: '12345678901',
          idType: t,
          selfieImageBase64: 'selfie-data',
        );
        expect(body['selfieImageBase64'], 'selfie-data');
      }
    });

    test('body carries exactly the two documented fields', () {
      final body = buildIdentityVerificationBody(
        idNumber: '12345678901',
        idType: IdType.bvn,
        selfieImageBase64: 'x',
      );
      expect(body.keys.length, 2);
    });
  });
}
