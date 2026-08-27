// test/kyc_status_test.dart
//
// Slice 4B: the server-authoritative KYC types (mirroring kudikit_auth_service's
// KycStatusSummary / enums). Verifies wire parsing round-trips for every enum
// value (including the multi-state ones that must NEVER be collapsed into
// booleans), safe defaults for unknown/missing values, and full
// KycStatusSummary JSON round-tripping.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/user/kyc_status.dart';

void main() {
  group('KycStatus', () {
    test('parses every wire value and round-trips', () {
      const cases = {
        'NOT_STARTED': KycStatus.notStarted,
        'PENDING': KycStatus.pending,
        'IN_PROGRESS': KycStatus.inProgress,
        'MANUAL_REVIEW': KycStatus.manualReview,
        'VERIFIED': KycStatus.verified,
        'REJECTED': KycStatus.rejected,
        'EXPIRED': KycStatus.expired,
      };
      cases.forEach((wire, expected) {
        final parsed = KycStatus.fromWire(wire);
        expect(parsed, expected, reason: 'fromWire($wire)');
        expect(parsed.wireValue, wire, reason: 'wireValue of $wire');
      });
    });

    test('unknown or missing values default to NOT_STARTED', () {
      expect(KycStatus.fromWire('GARBAGE'), KycStatus.notStarted);
      expect(KycStatus.fromWire(null), KycStatus.notStarted);
    });
  });

  group('IdDocumentStatus', () {
    test('parses every wire value and round-trips', () {
      const cases = {
        'NOT_STARTED': IdDocumentStatus.notStarted,
        'VERIFIED': IdDocumentStatus.verified,
        'REJECTED': IdDocumentStatus.rejected,
        'MANUAL_REVIEW': IdDocumentStatus.manualReview,
      };
      cases.forEach((wire, expected) {
        final parsed = IdDocumentStatus.fromWire(wire);
        expect(parsed, expected, reason: 'fromWire($wire)');
        expect(parsed.wireValue, wire, reason: 'wireValue of $wire');
      });
    });

    test('unknown or missing values default to NOT_STARTED', () {
      expect(IdDocumentStatus.fromWire('GARBAGE'), IdDocumentStatus.notStarted);
      expect(IdDocumentStatus.fromWire(null), IdDocumentStatus.notStarted);
    });
  });

  group('AddressVerificationStatus', () {
    test('parses every wire value and round-trips', () {
      const cases = {
        'NOT_STARTED': AddressVerificationStatus.notStarted,
        'PENDING_AGENT_VISIT': AddressVerificationStatus.pendingAgentVisit,
        'VERIFIED': AddressVerificationStatus.verified,
        'REJECTED': AddressVerificationStatus.rejected,
      };
      cases.forEach((wire, expected) {
        final parsed = AddressVerificationStatus.fromWire(wire);
        expect(parsed, expected, reason: 'fromWire($wire)');
        expect(parsed.wireValue, wire, reason: 'wireValue of $wire');
      });
    });

    test('unknown or missing values default to NOT_STARTED', () {
      expect(AddressVerificationStatus.fromWire('GARBAGE'),
          AddressVerificationStatus.notStarted);
      expect(AddressVerificationStatus.fromWire(null),
          AddressVerificationStatus.notStarted);
    });
  });

  group('UserStatus', () {
    test('parses every wire value and round-trips', () {
      const cases = {
        'PENDING_VERIFICATION': UserStatus.pendingVerification,
        'ACTIVE': UserStatus.active,
        'LOCKED': UserStatus.locked,
        'SUSPENDED': UserStatus.suspended,
        'CLOSED': UserStatus.closed,
      };
      cases.forEach((wire, expected) {
        final parsed = UserStatus.fromWire(wire);
        expect(parsed, expected, reason: 'fromWire($wire)');
        expect(parsed.wireValue, wire, reason: 'wireValue of $wire');
      });
    });

    test('unknown or missing values default to PENDING_VERIFICATION', () {
      expect(UserStatus.fromWire('GARBAGE'), UserStatus.pendingVerification);
      expect(UserStatus.fromWire(null), UserStatus.pendingVerification);
    });
  });

  group('KycStatusSummary', () {
    test('fromJson parses every field of the server summary', () {
      final summary = KycStatusSummary.fromJson({
        'status': 'MANUAL_REVIEW',
        'bvnVerified': true,
        'ninVerified': true,
        'livenessVerified': true,
        'idDocumentStatus': 'VERIFIED',
        'addressStatus': 'PENDING_AGENT_VISIT',
        'requiresManualReview': true,
      });

      expect(summary.status, KycStatus.manualReview);
      expect(summary.bvnVerified, isTrue);
      expect(summary.ninVerified, isTrue);
      expect(summary.livenessVerified, isTrue);
      expect(summary.idDocumentStatus, IdDocumentStatus.verified);
      expect(summary.addressStatus, AddressVerificationStatus.pendingAgentVisit);
      expect(summary.requiresManualReview, isTrue);
    });

    test('missing fields default to safe NOT_STARTED values', () {
      final summary = KycStatusSummary.fromJson(const {});

      expect(summary.status, KycStatus.notStarted);
      expect(summary.bvnVerified, isFalse);
      expect(summary.ninVerified, isFalse);
      expect(summary.livenessVerified, isFalse);
      expect(summary.idDocumentStatus, IdDocumentStatus.notStarted);
      expect(summary.addressStatus, AddressVerificationStatus.notStarted);
      expect(summary.requiresManualReview, isFalse);
    });

    test('toJson round-trips through fromJson', () {
      const original = KycStatusSummary(
        status: KycStatus.verified,
        bvnVerified: true,
        ninVerified: true,
        livenessVerified: true,
        idDocumentStatus: IdDocumentStatus.verified,
        addressStatus: AddressVerificationStatus.verified,
        requiresManualReview: false,
      );

      final restored = KycStatusSummary.fromJson(original.toJson());

      expect(restored.status, KycStatus.verified);
      expect(restored.bvnVerified, isTrue);
      expect(restored.ninVerified, isTrue);
      expect(restored.livenessVerified, isTrue);
      expect(restored.idDocumentStatus, IdDocumentStatus.verified);
      expect(restored.addressStatus, AddressVerificationStatus.verified);
      expect(restored.requiresManualReview, isFalse);
    });

    test('requiresManualReview survives the JSON round-trip', () {
      final summary = KycStatusSummary.fromJson({
        'status': 'PENDING',
        'requiresManualReview': true,
      }).toJson();

      expect(summary['requiresManualReview'], isTrue);
      expect(KycStatusSummary.fromJson(summary).requiresManualReview, isTrue);
    });

    test('rejection reasons survive the JSON round-trip (Slice 6)', () {
      final original = KycStatusSummary(
        status: KycStatus.rejected,
        rejectionReason: 'liveness failed',
        idDocumentRejectionReason: 'document mismatch',
        addressRejectionReason: 'bill not recent',
      );

      final restored = KycStatusSummary.fromJson(original.toJson());

      expect(restored.rejectionReason, 'liveness failed');
      expect(restored.idDocumentRejectionReason, 'document mismatch');
      expect(restored.addressRejectionReason, 'bill not recent');
      expect(restored.toJson()['idDocumentRejectionReason'], 'document mismatch');
    });

    test('tierUpgradeStatus/reviewNotes are parsed and round-trip (backend '
        'MEGA review lifecycle)', () {
      final original = KycStatusSummary(
        status: KycStatus.pending,
        tierUpgradeStatus: TierUpgradeStatus.reviewing,
        tierUpgradeReviewNotes: 'awaiting admin decision',
      );

      final restored = KycStatusSummary.fromJson(original.toJson());

      expect(restored.tierUpgradeStatus, TierUpgradeStatus.reviewing);
      expect(restored.tierUpgradeReviewNotes, 'awaiting admin decision');
      expect(restored.toJson()['tierUpgradeStatus'], 'REVIEWING');

      // Unknown/missing -> null (no active request), never a fabricated stage.
      expect(KycStatusSummary.fromJson({}).tierUpgradeStatus, isNull);
      expect(
        KycStatusSummary.fromJson({'tierUpgradeStatus': 'GARBAGE'})
            .tierUpgradeStatus,
        isNull,
      );
    });
  });

  group('TierUpgradeStatus', () {
    test('parses every wire value and round-trips', () {
      const cases = {
        'SUBMITTED': TierUpgradeStatus.submitted,
        'REVIEWING': TierUpgradeStatus.reviewing,
        'APPROVED': TierUpgradeStatus.approved,
        'REJECTED': TierUpgradeStatus.rejected,
      };
      cases.forEach((wire, expected) {
        final parsed = TierUpgradeStatus.fromWire(wire);
        expect(parsed, expected, reason: 'fromWire($wire)');
        expect(parsed!.wireValue, wire, reason: 'wireValue of $wire');
      });
    });

    test('unknown or missing values are null (no active request)', () {
      expect(TierUpgradeStatus.fromWire('GARBAGE'), isNull);
      expect(TierUpgradeStatus.fromWire(null), isNull);
    });
  });

  group('TierUpgradeStatusInfo (GET /auth/kyc/tier-upgrade/status)', () {
    test('maps the backend TierUpgradeStatusResponse fields', () {
      final info = TierUpgradeStatusInfo.fromJson({
        'targetTier': 'MEGA',
        'status': 'REVIEWING',
        'reviewNotes': 'address confirmed, awaiting decision',
        'submittedAt': '2026-08-18T10:00:00',
        'decidedAt': null,
      });

      expect(info.targetTier, 3);
      expect(info.status, TierUpgradeStatus.reviewing);
      expect(info.reviewNotes, 'address confirmed, awaiting decision');
      expect(info.submittedAt, DateTime.parse('2026-08-18T10:00:00'));
      expect(info.decidedAt, isNull);
    });

    test('empty body is a no-op (nulls)', () {
      final info = TierUpgradeStatusInfo.fromJson(const {});
      expect(info.status, isNull);
      expect(info.targetTier, isNull);
      expect(info.reviewNotes, isNull);
    });
  });
}