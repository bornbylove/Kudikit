// test/kyc_verify_contract_test.dart
//
// Slice 5: verifies the mobile → backend mapping rules for the KYC
// submission APIs that do NOT depend on the network:
//   • DocumentType wire mapping for POST /auth/kyc/verify-id-document
//   • front/back acquisition rules (passport back optional, 2-sided required)
//   • KycStatusSummary identity fields parsed from the full KycVerification
// The request-shape/HTTP tests live in auth_services_test.dart and the
// persistence tests in auth_provider_test.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';
import 'package:kudipay/model/user/kyc_status.dart';

void main() {
  group('DocumentType → backend wire mapping', () {
    test('every submittable type maps to the auth-service enum', () {
      expect(DocumentType.nationalId.backendValue, 'NATIONAL_ID');
      expect(DocumentType.driversLicense.backendValue, 'DRIVERS_LICENSE');
      expect(DocumentType.votersCard.backendValue, 'VOTERS_CARD');
      expect(DocumentType.passport.backendValue, 'PASSPORT');
    });
  });

  group('DocumentType back-side requirement', () {
    test('passport is the only document with an optional back', () {
      expect(DocumentType.passport.backRequired, isFalse);
      expect(DocumentType.nationalId.backRequired, isTrue);
      expect(DocumentType.driversLicense.backRequired, isTrue);
      expect(DocumentType.votersCard.backRequired, isTrue);
    });
  });

  group('DocumentUploadData.isComplete', () {
    final front = File('front.jpg');

    test('two-sided document without a back image cannot be submitted',
        () {
      final data = DocumentUploadData(
        documentType: DocumentType.nationalId,
        frontImage: front,
      );
      expect(data.isComplete, isFalse);
    });

    test('two-sided document with front AND back is submittable', () {
      final data = DocumentUploadData(
        documentType: DocumentType.nationalId,
        frontImage: front,
        backImage: File('back.jpg'),
      );
      expect(data.isComplete, isTrue);
    });

    test('passport is submittable with front only (back optional)', () {
      final data = DocumentUploadData(
        documentType: DocumentType.passport,
        frontImage: front,
      );
      expect(data.isComplete, isTrue);
    });

    test('no document type or no front image blocks submission', () {
      expect(DocumentUploadData().isComplete, isFalse);
      expect(
        DocumentUploadData(
          documentType: DocumentType.passport,
          frontImage: null,
        ).isComplete,
        isFalse,
      );
    });
  });

  group('KycStatusSummary identity fields from the full entity', () {
    test('fromJson reads bvn identity details for a BVN response', () {
      final summary = KycStatusSummary.fromJson({
        'status': 'VERIFIED',
        'bvnVerified': true,
        'ninVerified': false,
        'livenessVerified': true,
        'idDocumentStatus': 'NOT_STARTED',
        'addressStatus': 'NOT_STARTED',
        'requiresManualReview': false,
        'bvnFullName': 'ABRAHAM CHIDUBEM',
        'bvnDateOfBirth': '1995-05-15',
      });

      expect(summary.fullName, 'ABRAHAM CHIDUBEM');
      expect(summary.dateOfBirth, '1995-05-15');
    });

    test('fromJson reads nin identity details for a NIN response', () {
      final summary = KycStatusSummary.fromJson({
        'status': 'VERIFIED',
        'bvnVerified': true,
        'ninVerified': true,
        'livenessVerified': true,
        'idDocumentStatus': 'NOT_STARTED',
        'addressStatus': 'NOT_STARTED',
        'requiresManualReview': false,
        'ninFullName': 'NGOZI OKONKWO',
        'ninDateOfBirth': '1990-02-20',
      });

      expect(summary.fullName, 'NGOZI OKONKWO');
      expect(summary.dateOfBirth, '1990-02-20');
    });

    test('identity fields are null when the entity carries neither', () {
      final summary = KycStatusSummary.fromJson(const {
        'status': 'PENDING',
        'bvnVerified': false,
        'ninVerified': false,
        'livenessVerified': false,
        'idDocumentStatus': 'NOT_STARTED',
        'addressStatus': 'NOT_STARTED',
        'requiresManualReview': false,
      });

      expect(summary.fullName, isNull);
      expect(summary.dateOfBirth, isNull);
    });

    test('identity fields are transport-only and are NOT persisted', () {
      final restored = KycStatusSummary.fromJson(
        KycStatusSummary(
          status: KycStatus.verified,
          bvnVerified: true,
          ninVerified: false,
          livenessVerified: true,
          idDocumentStatus: IdDocumentStatus.verified,
          addressStatus: AddressVerificationStatus.pendingAgentVisit,
          requiresManualReview: false,
          fullName: 'ABRAHAM CHIDUBEM',
          dateOfBirth: '1995-05-15',
        ).toJson(),
      );

      // fullName/dateOfBirth only ever flow from the API entity (transport-only).
      expect(restored.fullName, isNull);
      expect(restored.dateOfBirth, isNull);
      // The authoritative fields DO survive persistence.
      expect(restored.status, KycStatus.verified);
      expect(restored.idDocumentStatus, IdDocumentStatus.verified);
      expect(restored.addressStatus,
          AddressVerificationStatus.pendingAgentVisit);
    });
  });
}