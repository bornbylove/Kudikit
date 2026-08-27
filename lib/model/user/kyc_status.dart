// lib/model/user/kyc_status.dart
// ─────────────────────────────────────────────────────────────────────────────
// Server-authoritative KYC state types, mirroring kudikit_auth_service's
// KycStatusSummary / enums exactly (verified 2026-08). The auth-service is the
// source of truth for KYC; UserModel is a representation/cache of that truth.
//
// These enums deliberately carry the FULL multi-state semantics — they must
// NOT be collapsed into booleans. A convenience boolean like `isBvnVerified`
// may be derived from this state, but it never replaces it.
//
// Unknown/missing values parse to a safe default so old persisted UserModel
// JSON (which predates these fields) still deserializes.
// ─────────────────────────────────────────────────────────────────────────────

enum KycStatus {
  notStarted,
  pending,
  inProgress,
  manualReview,
  verified,
  rejected,
  expired;

  static KycStatus fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return KycStatus.pending;
      case 'IN_PROGRESS':
        return KycStatus.inProgress;
      case 'MANUAL_REVIEW':
        return KycStatus.manualReview;
      case 'VERIFIED':
        return KycStatus.verified;
      case 'REJECTED':
        return KycStatus.rejected;
      case 'EXPIRED':
        return KycStatus.expired;
      case 'NOT_STARTED':
      default:
        return KycStatus.notStarted;
    }
  }

  String get wireValue {
    switch (this) {
      case KycStatus.notStarted:
        return 'NOT_STARTED';
      case KycStatus.pending:
        return 'PENDING';
      case KycStatus.inProgress:
        return 'IN_PROGRESS';
      case KycStatus.manualReview:
        return 'MANUAL_REVIEW';
      case KycStatus.verified:
        return 'VERIFIED';
      case KycStatus.rejected:
        return 'REJECTED';
      case KycStatus.expired:
        return 'EXPIRED';
    }
  }
}

enum IdDocumentStatus {
  notStarted,
  verified,
  rejected,
  manualReview;

  static IdDocumentStatus fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'VERIFIED':
        return IdDocumentStatus.verified;
      case 'REJECTED':
        return IdDocumentStatus.rejected;
      case 'MANUAL_REVIEW':
        return IdDocumentStatus.manualReview;
      case 'NOT_STARTED':
      default:
        return IdDocumentStatus.notStarted;
    }
  }

  String get wireValue {
    switch (this) {
      case IdDocumentStatus.notStarted:
        return 'NOT_STARTED';
      case IdDocumentStatus.verified:
        return 'VERIFIED';
      case IdDocumentStatus.rejected:
        return 'REJECTED';
      case IdDocumentStatus.manualReview:
        return 'MANUAL_REVIEW';
    }
  }
}

enum AddressVerificationStatus {
  notStarted,
  pendingAgentVisit,
  verified,
  rejected;

  static AddressVerificationStatus fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING_AGENT_VISIT':
        return AddressVerificationStatus.pendingAgentVisit;
      case 'VERIFIED':
        return AddressVerificationStatus.verified;
      case 'REJECTED':
        return AddressVerificationStatus.rejected;
      case 'NOT_STARTED':
      default:
        return AddressVerificationStatus.notStarted;
    }
  }

  String get wireValue {
    switch (this) {
      case AddressVerificationStatus.notStarted:
        return 'NOT_STARTED';
      case AddressVerificationStatus.pendingAgentVisit:
        return 'PENDING_AGENT_VISIT';
      case AddressVerificationStatus.verified:
        return 'VERIFIED';
      case AddressVerificationStatus.rejected:
        return 'REJECTED';
    }
  }
}

/// Tier-upgrade lifecycle status (backend MEGA human-review gate, added
/// 2026-08 on top of pendingTier). Unlike the PRD's coarse "Pending" DISPLAY,
/// this is the internal SUBMITTED -> REVIEWING -> APPROVED/REJECTED state from
/// the auth-service's TierUpgradeRequest. The mobile carries it on the
/// UserModel for logic but never surfaces the staged labels to the user.
enum TierUpgradeStatus {
  submitted,
  reviewing,
  approved,
  rejected;

  /// Null when missing/unknown — meaning "no active request", matching the
  /// backend's null tierUpgradeStatus.
  static TierUpgradeStatus? fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUBMITTED':
        return submitted;
      case 'REVIEWING':
        return reviewing;
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      default:
        return null;
    }
  }

  String get wireValue {
    switch (this) {
      case TierUpgradeStatus.submitted:
        return 'SUBMITTED';
      case TierUpgradeStatus.reviewing:
        return 'REVIEWING';
      case TierUpgradeStatus.approved:
        return 'APPROVED';
      case TierUpgradeStatus.rejected:
        return 'REJECTED';
    }
  }
}

/// The latest TierUpgradeRequest, as returned by
/// GET /auth/kyc/tier-upgrade/status. targetTier is mapped from the backend
/// AccountTier string (BASIC/PRO/MEGA -> 1/2/3). Carried internally on
/// UserModel; never exposed as staged UI labels (PRD "Pending" display).
class TierUpgradeStatusInfo {
  final int? targetTier;
  final TierUpgradeStatus? status;
  final String? reviewNotes;
  final DateTime? submittedAt;
  final DateTime? decidedAt;

  const TierUpgradeStatusInfo({
    this.targetTier,
    this.status,
    this.reviewNotes,
    this.submittedAt,
    this.decidedAt,
  });

  factory TierUpgradeStatusInfo.fromJson(Map<String, dynamic> json) {
    return TierUpgradeStatusInfo(
      targetTier: _tierNumberFromString(json['targetTier'] as String?),
      status: TierUpgradeStatus.fromWire(json['status'] as String?),
      reviewNotes: json['reviewNotes'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      decidedAt: json['decidedAt'] != null
          ? DateTime.tryParse(json['decidedAt'] as String)
          : null,
    );
  }

  static int? _tierNumberFromString(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'PRO':
        return 2;
      case 'MEGA':
        return 3;
      case 'BASIC':
        return 1;
      default:
        return null;
    }
  }
}

enum UserStatus {
  pendingVerification,
  active,
  locked,
  suspended,
  closed;

  static UserStatus fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'LOCKED':
        return UserStatus.locked;
      case 'SUSPENDED':
        return UserStatus.suspended;
      case 'CLOSED':
        return UserStatus.closed;
      case 'PENDING_VERIFICATION':
      default:
        return UserStatus.pendingVerification;
    }
  }

  String get wireValue {
    switch (this) {
      case UserStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case UserStatus.active:
        return 'ACTIVE';
      case UserStatus.locked:
        return 'LOCKED';
      case UserStatus.suspended:
        return 'SUSPENDED';
      case UserStatus.closed:
        return 'CLOSED';
    }
  }
}

/// Server-authoritative KYC summary — the `user.kyc` object of an
/// AuthTokenResponse, and the response body of GET /auth/kyc/status.
///
/// [fullName] / [dateOfBirth] are transport-only identity details surfaced by
/// the verify-* / GET /auth/kyc/status responses (bvn/ninFullName + DateOfBirth
/// on the full KycVerification entity). They are NOT part of the authoritative
/// seven-field summary that is persisted into UserModel via copyWithKyc — they
/// exist so the BVN/NIN confirm screen can display the registry name/DOB.
///
/// The `*RejectionReason` fields (Slice 6) are read from the FULL KycVerification
/// entity returned by GET /auth/kyc/status so REJECTED/MANUAL_REVIEW states can
/// be surfaced with the server's reason instead of a dead loading screen.
class KycStatusSummary {
  final KycStatus status;
  final bool bvnVerified;
  final bool ninVerified;
  final bool livenessVerified;
  final IdDocumentStatus idDocumentStatus;
  final AddressVerificationStatus addressStatus;
  final bool requiresManualReview;
  final String? fullName;
  final String? dateOfBirth;
  final String? rejectionReason;
  final String? idDocumentRejectionReason;
  final String? addressRejectionReason;
  // Tier-upgrade lifecycle (backend MEGA review gate): the latest
  // TierUpgradeRequest status + admin notes, carried internally. Present in
  // auth UserResponse `user.kyc` and in GET /auth/kyc/status once the
  // auth-service populates them.
  final TierUpgradeStatus? tierUpgradeStatus;
  final String? tierUpgradeReviewNotes;

  const KycStatusSummary({
    this.status = KycStatus.notStarted,
    this.bvnVerified = false,
    this.ninVerified = false,
    this.livenessVerified = false,
    this.idDocumentStatus = IdDocumentStatus.notStarted,
    this.addressStatus = AddressVerificationStatus.notStarted,
    this.requiresManualReview = false,
    this.fullName,
    this.dateOfBirth,
    this.rejectionReason,
    this.idDocumentRejectionReason,
    this.addressRejectionReason,
    this.tierUpgradeStatus,
    this.tierUpgradeReviewNotes,
  });

  factory KycStatusSummary.fromJson(Map<String, dynamic> json) {
    return KycStatusSummary(
      status: KycStatus.fromWire(json['status'] as String?),
      bvnVerified: json['bvnVerified'] as bool? ?? false,
      ninVerified: json['ninVerified'] as bool? ?? false,
      livenessVerified: json['livenessVerified'] as bool? ?? false,
      idDocumentStatus: IdDocumentStatus.fromWire(
          json['idDocumentStatus'] as String?),
      addressStatus: AddressVerificationStatus.fromWire(
          json['addressStatus'] as String?),
      requiresManualReview: json['requiresManualReview'] as bool? ?? false,
      fullName: json['bvnFullName'] as String? ?? json['ninFullName'] as String?,
      dateOfBirth:
          json['bvnDateOfBirth'] as String? ?? json['ninDateOfBirth'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      idDocumentRejectionReason: json['idDocumentRejectionReason'] as String?,
      addressRejectionReason: json['addressRejectionReason'] as String?,
      tierUpgradeStatus:
          TierUpgradeStatus.fromWire(json['tierUpgradeStatus'] as String?),
      tierUpgradeReviewNotes: json['tierUpgradeReviewNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.wireValue,
      'bvnVerified': bvnVerified,
      'ninVerified': ninVerified,
      'livenessVerified': livenessVerified,
      'idDocumentStatus': idDocumentStatus.wireValue,
      'addressStatus': addressStatus.wireValue,
      'requiresManualReview': requiresManualReview,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'rejectionReason': rejectionReason,
      'idDocumentRejectionReason': idDocumentRejectionReason,
      'addressRejectionReason': addressRejectionReason,
      'tierUpgradeStatus': tierUpgradeStatus?.wireValue,
      'tierUpgradeReviewNotes': tierUpgradeReviewNotes,
    };
  }
}