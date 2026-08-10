// test/kyc_request_builders_test.dart
//
// Pins the wire contract for verify-bvn / verify-nin against /v3/api-docs.
// These field names are the exact thing that was wrong before the audit
// (the old code sent id_number/id_type to a path that did not exist), so they
// are worth asserting literally.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';
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

  group('idDocumentTypeWire', () {
    test('maps each accepted type to its server enum value', () {
      expect(idDocumentTypeWire(DocumentType.passport), 'PASSPORT');
      expect(
          idDocumentTypeWire(DocumentType.driversLicense), 'DRIVERS_LICENSE');
      expect(idDocumentTypeWire(DocumentType.nationalId), 'NATIONAL_ID');
      expect(idDocumentTypeWire(DocumentType.votersCard), 'VOTERS_CARD');
    });

    test('utility bill is not an ID document', () {
      // It is proof of address and belongs to verify-address instead.
      expect(idDocumentTypeWire(DocumentType.utilityBill), isNull);
    });

    test('kIdDocumentTypes contains exactly the mappable types', () {
      final mappable = DocumentType.values
          .where((t) => idDocumentTypeWire(t) != null)
          .toList();
      // Unordered: kIdDocumentTypes drives picker display order, which is a
      // presentation choice and need not match enum declaration order.
      expect(kIdDocumentTypes, unorderedEquals(mappable));
      expect(kIdDocumentTypes.length, 4);
      expect(kIdDocumentTypes.contains(DocumentType.utilityBill), isFalse);
    });

    test('every wire value is one the server declares', () {
      const serverEnum = {
        'PASSPORT',
        'DRIVERS_LICENSE',
        'NATIONAL_ID',
        'VOTERS_CARD',
      };
      for (final t in kIdDocumentTypes) {
        expect(serverEnum.contains(idDocumentTypeWire(t)), isTrue,
            reason: '${t.name} -> ${idDocumentTypeWire(t)}');
      }
    });
  });

  group('buildVerifyIdDocumentBody', () {
    test('includes the back image when supplied', () {
      final body = buildVerifyIdDocumentBody(
        documentTypeWire: 'NATIONAL_ID',
        frontImageBase64: 'FRONT',
        backImageBase64: 'BACK',
      );
      expect(body, {
        'documentType': 'NATIONAL_ID',
        'frontImageBase64': 'FRONT',
        'backImageBase64': 'BACK',
      });
    });

    test('omits the back image key entirely when null', () {
      final body = buildVerifyIdDocumentBody(
        documentTypeWire: 'PASSPORT',
        frontImageBase64: 'FRONT',
      );
      // Sending an explicit null could fail the server's string validation —
      // the key must be absent, not present-and-null.
      expect(body.containsKey('backImageBase64'), isFalse);
      expect(body, {
        'documentType': 'PASSPORT',
        'frontImageBase64': 'FRONT',
      });
    });

    test('never emits the pre-audit field names', () {
      final body = buildVerifyIdDocumentBody(
        documentTypeWire: 'PASSPORT',
        frontImageBase64: 'x',
      );
      expect(body.containsKey('document'), isFalse);
      expect(body.containsKey('document_type'), isFalse);
    });
  });

  group('kVerifyIdDocumentPath', () {
    test('is relative to the /api/v1 base url', () {
      expect(kVerifyIdDocumentPath, '/auth/kyc/verify-id-document');
      expect(kVerifyIdDocumentPath.contains('/api/v1'), isFalse);
    });
  });

  group('buildVerifyAddressBody', () {
    Map<String, dynamic> build({String? landmark, String? area}) =>
        buildVerifyAddressBody(
          houseNumber: '12',
          street: 'Adeola Odeku',
          lga: 'Eti-Osa',
          city: 'Lagos',
          state: 'Lagos',
          utilityBillImageBase64: 'BILL',
          landmark: landmark,
          area: area,
        );

    test('emits the documented field names', () {
      expect(build(), {
        'houseNumber': '12',
        'street': 'Adeola Odeku',
        'lga': 'Eti-Osa',
        'city': 'Lagos',
        'state': 'Lagos',
        'utilityBillImageBase64': 'BILL',
      });
    });

    test('never emits the pre-audit snake_case names', () {
      final body = build();
      expect(body.containsKey('street_name'), isFalse);
      expect(body.containsKey('house_number'), isFalse);
    });

    test('always includes every required key', () {
      // They are minLength:0 server-side, so presence matters, not content.
      final body = buildVerifyAddressBody(
        houseNumber: '',
        street: '',
        lga: '',
        city: '',
        state: '',
        utilityBillImageBase64: 'BILL',
      );
      for (final key in [
        'houseNumber',
        'street',
        'lga',
        'city',
        'state',
        'utilityBillImageBase64',
      ]) {
        expect(body.containsKey(key), isTrue, reason: key);
      }
    });

    test('includes the optional fields when populated', () {
      final body = build(landmark: 'Near the mall', area: 'Victoria Island');
      expect(body['landmark'], 'Near the mall');
      expect(body['area'], 'Victoria Island');
    });

    test('omits optional fields when null or blank', () {
      expect(build().containsKey('landmark'), isFalse);
      expect(build().containsKey('area'), isFalse);
      expect(build(landmark: '', area: '').containsKey('landmark'), isFalse);
      expect(build(landmark: '', area: '').containsKey('area'), isFalse);
    });

    test('the utility bill is always present — it is required', () {
      expect(build()['utilityBillImageBase64'], 'BILL');
    });
  });

  group('kVerifyAddressPath', () {
    test('is relative to the /api/v1 base url', () {
      expect(kVerifyAddressPath, '/auth/kyc/verify-address');
      expect(kVerifyAddressPath.contains('/api/v1'), isFalse);
    });
  });
}
