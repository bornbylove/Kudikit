// test/kyc_status_mapper_test.dart
//
// Covers the GET /auth/kyc/status payload mapping. Field names and enum
// values here are taken from the backend's OpenAPI spec (GET /v3/api-docs,
// components.schemas.KycVerification) — not invented.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_status_mapper.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

void main() {
  group('envelope handling', () {
    test('reads fields from inside the data envelope', () {
      final entity = kycStatusFromResponse({
        'status': 'success',
        'message': 'OK',
        'errorCode': null,
        'data': {'status': 'VERIFIED', 'bvnVerified': true},
      });

      // The envelope's own top-level status:'success' must not be mistaken
      // for the KYC status enum.
      expect(entity.overall, KycOverallStatus.verified);
      expect(entity.bvnVerified, isTrue);
    });

    test('falls back to a bare, non-enveloped payload', () {
      final entity = kycStatusFromResponse({'status': 'REJECTED'});
      expect(entity.overall, KycOverallStatus.rejected);
    });

    test('an empty response degrades to notStarted rather than throwing', () {
      final entity = kycStatusFromResponse({});
      expect(entity.overall, KycOverallStatus.notStarted);
      expect(entity.bvnVerified, isFalse);
      expect(entity.documentStatus, KycDocumentStatus.notStarted);
      expect(entity.addressStatus, KycAddressStatus.notStarted);
    });
  });

  group('overall status parsing', () {
    test('maps every value in the spec enum', () {
      const cases = {
        'NOT_STARTED': KycOverallStatus.notStarted,
        'PENDING': KycOverallStatus.pending,
        'IN_PROGRESS': KycOverallStatus.inProgress,
        'MANUAL_REVIEW': KycOverallStatus.manualReview,
        'VERIFIED': KycOverallStatus.verified,
        'REJECTED': KycOverallStatus.rejected,
        'EXPIRED': KycOverallStatus.expired,
      };
      cases.forEach((wire, expected) {
        expect(parseKycOverallStatus(wire), expected, reason: wire);
      });
    });

    test('unknown or null values degrade to notStarted', () {
      expect(
          parseKycOverallStatus('SOMETHING_NEW'), KycOverallStatus.notStarted);
      expect(parseKycOverallStatus(null), KycOverallStatus.notStarted);
    });
  });

  group('document and address status parsing', () {
    test('maps document enum values', () {
      expect(parseKycDocumentStatus('VERIFIED'), KycDocumentStatus.verified);
      expect(parseKycDocumentStatus('REJECTED'), KycDocumentStatus.rejected);
      expect(parseKycDocumentStatus('MANUAL_REVIEW'),
          KycDocumentStatus.manualReview);
      expect(parseKycDocumentStatus(null), KycDocumentStatus.notStarted);
    });

    test('maps address enum values', () {
      expect(parseKycAddressStatus('PENDING_AGENT_VISIT'),
          KycAddressStatus.pendingAgentVisit);
      expect(parseKycAddressStatus('VERIFIED'), KycAddressStatus.verified);
      expect(parseKycAddressStatus('REJECTED'), KycAddressStatus.rejected);
      expect(parseKycAddressStatus(null), KycAddressStatus.notStarted);
    });

    test('address PENDING_AGENT_VISIT does not count as verified', () {
      final entity = kycStatusFromResponse({
        'data': {'addressStatus': 'PENDING_AGENT_VISIT'},
      });
      expect(entity.addressStatus, KycAddressStatus.pendingAgentVisit);
      expect(entity.addressVerified, isFalse);
    });
  });

  group('derived getters', () {
    test('isComplete only when overall is VERIFIED', () {
      expect(
        kycStatusFromResponse({
          'data': {'status': 'VERIFIED'}
        }).isComplete,
        isTrue,
      );
      expect(
        kycStatusFromResponse({
          'data': {'status': 'MANUAL_REVIEW'}
        }).isComplete,
        isFalse,
      );
    });

    test('verifiedFullName prefers the BVN name over the NIN name', () {
      final both = kycStatusFromResponse({
        'data': {'bvnFullName': 'Ada Lovelace', 'ninFullName': 'A. Lovelace'},
      });
      expect(both.verifiedFullName, 'Ada Lovelace');
    });

    test('verifiedFullName falls back to the NIN name', () {
      final ninOnly = kycStatusFromResponse({
        'data': {'ninFullName': 'Ada Lovelace'},
      });
      expect(ninOnly.verifiedFullName, 'Ada Lovelace');
    });

    test('verifiedFullName is null when neither check has returned', () {
      expect(kycStatusFromResponse({}).verifiedFullName, isNull);
    });
  });

  test('maps a realistic fully-verified payload', () {
    final entity = kycStatusFromResponse({
      'status': 'success',
      'data': {
        'status': 'VERIFIED',
        'bvnVerified': true,
        'ninVerified': false,
        'livenessVerified': true,
        'idDocumentStatus': 'VERIFIED',
        'addressStatus': 'VERIFIED',
        'requiresManualReview': false,
        'rejectionReason': null,
        'bvnFullName': 'Ada Lovelace',
        'bvnMatchConfidence': 0.97,
        'vendorReferenceId': 'vendor-123',
      },
    });

    expect(entity.isComplete, isTrue);
    expect(entity.bvnVerified, isTrue);
    expect(entity.ninVerified, isFalse);
    expect(entity.livenessVerified, isTrue);
    expect(entity.documentVerified, isTrue);
    expect(entity.addressVerified, isTrue);
    expect(entity.requiresManualReview, isFalse);
    expect(entity.rejectionReason, isNull);
    expect(entity.verifiedFullName, 'Ada Lovelace');
  });
}
