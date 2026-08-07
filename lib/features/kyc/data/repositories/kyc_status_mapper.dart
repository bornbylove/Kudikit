// lib/features/kyc/data/repositories/kyc_status_mapper.dart
//
// Maps the KycVerification payload from GET /auth/kyc/status onto the domain
// entity. Kept as a pure function, separate from the repository, so the enum
// mapping can be unit-tested without a Dio/HTTP fake.
//
// The server sends ~50 fields; only what the app actually consumes is mapped.
// Unknown or absent enum values degrade to the "not started" variant rather
// than throwing — a KYC screen showing "not started" is recoverable, a parse
// exception mid-onboarding is not.

import 'package:kudipay/core/network/api_envelope.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

KycOverallStatus parseKycOverallStatus(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'PENDING':
      return KycOverallStatus.pending;
    case 'IN_PROGRESS':
      return KycOverallStatus.inProgress;
    case 'MANUAL_REVIEW':
      return KycOverallStatus.manualReview;
    case 'VERIFIED':
      return KycOverallStatus.verified;
    case 'REJECTED':
      return KycOverallStatus.rejected;
    case 'EXPIRED':
      return KycOverallStatus.expired;
    default:
      return KycOverallStatus.notStarted;
  }
}

KycDocumentStatus parseKycDocumentStatus(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'VERIFIED':
      return KycDocumentStatus.verified;
    case 'REJECTED':
      return KycDocumentStatus.rejected;
    case 'MANUAL_REVIEW':
      return KycDocumentStatus.manualReview;
    default:
      return KycDocumentStatus.notStarted;
  }
}

KycAddressStatus parseKycAddressStatus(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'PENDING_AGENT_VISIT':
      return KycAddressStatus.pendingAgentVisit;
    case 'VERIFIED':
      return KycAddressStatus.verified;
    case 'REJECTED':
      return KycAddressStatus.rejected;
    default:
      return KycAddressStatus.notStarted;
  }
}

/// Builds a [KycStatusEntity] from a status response. Accepts either the full
/// enveloped response or a bare payload.
KycStatusEntity kycStatusFromResponse(Map<String, dynamic> res) {
  final data = unwrapPayload(res);

  return KycStatusEntity(
    overall: parseKycOverallStatus(data['status'] as String?),
    bvnVerified: data['bvnVerified'] as bool? ?? false,
    ninVerified: data['ninVerified'] as bool? ?? false,
    livenessVerified: data['livenessVerified'] as bool? ?? false,
    documentStatus: parseKycDocumentStatus(data['idDocumentStatus'] as String?),
    addressStatus: parseKycAddressStatus(data['addressStatus'] as String?),
    requiresManualReview: data['requiresManualReview'] as bool? ?? false,
    rejectionReason: data['rejectionReason'] as String?,
    bvnFullName: data['bvnFullName'] as String?,
    ninFullName: data['ninFullName'] as String?,
    bvnDateOfBirth: _parseDate(data['bvnDateOfBirth']),
    ninDateOfBirth: _parseDate(data['ninDateOfBirth']),
  );
}

/// Bureau dates arrive as `yyyy-MM-dd`. A malformed value degrades to null
/// rather than throwing — see the note at the top of this file.
DateTime? _parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
