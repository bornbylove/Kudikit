import 'package:kudipay/model/user/kyc_status.dart';

class UserModel {
  final String userId;
  final String email;
  final String phoneNumber;
  final String? name;
  final String? bvn;
  final String? nin;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBvnVerified;
  final bool isAddressVerified;
  final bool isSelfieVerified;
  final bool isDocumentVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  // The tier the user selected during onboarding (1 = Basic, 2 = Pro, 3 = Mega).
  // Defaults to 1. Stored on the model so it survives logout/login cycles via
  // StorageService and is available everywhere without a separate provider read.
  final int selectedTier;

  // ── Server-authoritative KYC state (Slice 4B) ─────────────────────────────
  // The auth-service owns KYC truth; these fields are a representation/cache
  // of that truth. The multi-state enums deliberately retain FULL semantics
  // (PENDING, IN_PROGRESS, MANUAL_REVIEW, REJECTED, EXPIRED, PENDING_AGENT_VISIT
  // are all distinguishable — never collapsed into booleans). The convenience
  // booleans above (isBvnVerified/isSelfieVerified/isDocumentVerified/
  // isAddressVerified) are derived from this state whenever server KYC data is
  // present, and may only lag behind it during transitional local-optimistic
  // UI mutations (see AuthProvider.updateKycStatus).
  final KycStatus kycStatus;
  final IdDocumentStatus idDocumentStatus;
  final AddressVerificationStatus addressStatus;
  final bool requiresManualReview;
  final bool isNinVerified;
  final UserStatus? userStatus;
  final bool registrationComplete;
  final int? pendingTier;
  // Tier-upgrade lifecycle (backend MEGA review gate): carried internally for
  // logic; never surfaced as staged UI labels (PRD "Pending" display).
  final TierUpgradeStatus? tierUpgradeStatus;
  final String? tierUpgradeReviewNotes;

  // ── GRANTED tier (Slice 7 P0-3) ───────────────────────────────────────────
  // The server-authoritative GRANTED tier from the auth-service `tier` field
  // (1 = Basic, 2 = Pro, 3 = Mega). null means NO tier has been granted —
  // the user is UNVERIFIED. This is deliberately separate from pendingTier
  // (the tier being worked toward) and selectedTier (local routing intent):
  // a pending or locally-selected tier must NEVER be displayed as granted.
  final int? grantedTier;
  // Slice 6: server-provided rejection/review reasons (read from the full
  // KycVerification entity via GET /auth/kyc/status) so REJECTED/MANUAL_REVIEW
  // states can be surfaced with the server's reason.
  final String? rejectionReason;
  final String? idDocumentRejectionReason;
  final String? addressRejectionReason;

  UserModel({
    required this.userId,
    required this.email,
    required this.phoneNumber,
    this.name,
    this.bvn,
    this.nin,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isBvnVerified = false,
    this.isAddressVerified = false,
    this.isSelfieVerified = false,
    this.isDocumentVerified = false,
    this.createdAt,
    this.lastLogin,
    this.selectedTier = 1,
    this.kycStatus = KycStatus.notStarted,
    this.idDocumentStatus = IdDocumentStatus.notStarted,
    this.addressStatus = AddressVerificationStatus.notStarted,
    this.requiresManualReview = false,
    this.isNinVerified = false,
    this.userStatus,
    this.registrationComplete = false,
    this.pendingTier,
    this.grantedTier,
    this.rejectionReason,
    this.idDocumentRejectionReason,
    this.addressRejectionReason,
    this.tierUpgradeStatus,
    this.tierUpgradeReviewNotes,
  });

  // Check if KYC is complete.
  // AUTHORITATIVE (Slice 4B): the server's top-level KycStatus is the single
  // source of truth. The derived booleans (isBvnVerified && isSelfieVerified
  // && isDocumentVerified && isAddressVerified) are NOT authoritative — they
  // may remain useful for legacy progress calculations but must not gate
  // completion.
  bool get isKycComplete => kycStatus == KycStatus.verified;

  // Get KYC completion percentage — legacy heuristic retained for the
  // progress widget / transitional UI. Derived booleans are used here because
  // they map 1:1 to the old progress bar; this is NOT a completion gate.
  double get kycProgress {
    int completed = 0;
    if (isEmailVerified) completed++;
    if (isBvnVerified) completed++;
    if (isAddressVerified) completed++;
    if (isSelfieVerified) completed++;
    if (isDocumentVerified) completed++;
    return completed / 5.0;
  }

  // ── PRD tier-requirement checks (Slice 6) ─────────────────────────────────
  // The PRD tier model is the authority: Basic = Selfie + (BVN OR NIN);
  // Pro = Basic + BVN AND NIN + valid ID; Mega = Pro + verified address.
  // These are pure, UI-independent checks so routing and tests share one source
  // of truth. Note they deliberately do NOT consult top-level KycStatus: the
  // server's top-level status flips to VERIFIED as soon as BVN OR NIN succeeds,
  // which is NOT equivalent to Pro/Mega completion (see Slice 6 report).
  bool get basicRequirementsSatisfied =>
      isSelfieVerified && (isBvnVerified || isNinVerified);

  bool get proRequirementsSatisfied =>
      basicRequirementsSatisfied &&
      isBvnVerified &&
      isNinVerified &&
      idDocumentStatus == IdDocumentStatus.verified;

  bool get megaRequirementsSatisfied =>
      proRequirementsSatisfied &&
      addressStatus == AddressVerificationStatus.verified;

  /// Whether all of [tierNumber]'s PRD requirements are satisfied (1/2/3).
  bool isTierComplete(int tierNumber) {
    switch (tierNumber) {
      case 2:
        return proRequirementsSatisfied;
      case 3:
        return megaRequirementsSatisfied;
      default:
        return basicRequirementsSatisfied;
    }
  }

  // ── GRANTED tier semantics (Slice 7 P0-3) ────────────────────────────────
  /// The server-authoritative granted tier, or 0 when no tier has been granted
  /// (UNVERIFIED). 0 is the canonical "no grant" sentinel used everywhere a
  /// tier number is needed.
  int get grantedTierOrZero => grantedTier ?? 0;

  /// Whether a tier has actually been granted by the server.
  bool get hasGrantedTier {
    final t = grantedTier;
    return t != null && t >= 1 && t <= 3;
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? phoneNumber,
    String? name,
    String? bvn,
    String? nin,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? selectedTier,
    KycStatus? kycStatus,
    IdDocumentStatus? idDocumentStatus,
    AddressVerificationStatus? addressStatus,
    bool? requiresManualReview,
    bool? isNinVerified,
    UserStatus? userStatus,
    bool? registrationComplete,
    int? pendingTier,
    int? grantedTier,
    String? rejectionReason,
    String? idDocumentRejectionReason,
    String? addressRejectionReason,
    TierUpgradeStatus? tierUpgradeStatus,
    String? tierUpgradeReviewNotes,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      bvn: bvn ?? this.bvn,
      nin: nin ?? this.nin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isBvnVerified: isBvnVerified ?? this.isBvnVerified,
      isAddressVerified: isAddressVerified ?? this.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? this.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? this.isDocumentVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      selectedTier: selectedTier ?? this.selectedTier,
      kycStatus: kycStatus ?? this.kycStatus,
      idDocumentStatus: idDocumentStatus ?? this.idDocumentStatus,
      addressStatus: addressStatus ?? this.addressStatus,
      requiresManualReview: requiresManualReview ?? this.requiresManualReview,
      isNinVerified: isNinVerified ?? this.isNinVerified,
      userStatus: userStatus ?? this.userStatus,
      registrationComplete: registrationComplete ?? this.registrationComplete,
      pendingTier: pendingTier ?? this.pendingTier,
      grantedTier: grantedTier ?? this.grantedTier,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      idDocumentRejectionReason:
          idDocumentRejectionReason ?? this.idDocumentRejectionReason,
      addressRejectionReason:
          addressRejectionReason ?? this.addressRejectionReason,
      tierUpgradeStatus: tierUpgradeStatus ?? this.tierUpgradeStatus,
      tierUpgradeReviewNotes:
          tierUpgradeReviewNotes ?? this.tierUpgradeReviewNotes,
    );
  }

  /// Applies an authoritative server KYC summary (Slice 4B). The server wins:
  /// typed state is replaced wholesale and the convenience booleans are
  /// re-derived from it — cached local KYC flags are never preserved over
  /// server KYC data. Identity/persistence fields (createdAt, selectedTier,
  /// etc.) are left untouched.
  UserModel copyWithKyc(KycStatusSummary kyc) {
    return copyWith(
      kycStatus: kyc.status,
      idDocumentStatus: kyc.idDocumentStatus,
      addressStatus: kyc.addressStatus,
      requiresManualReview: kyc.requiresManualReview,
      isNinVerified: kyc.ninVerified,
      isBvnVerified: kyc.bvnVerified,
      isSelfieVerified: kyc.livenessVerified,
      isDocumentVerified: kyc.idDocumentStatus == IdDocumentStatus.verified,
      isAddressVerified: kyc.addressStatus == AddressVerificationStatus.verified,
      rejectionReason: kyc.rejectionReason,
      idDocumentRejectionReason: kyc.idDocumentRejectionReason,
      addressRejectionReason: kyc.addressRejectionReason,
      tierUpgradeStatus: kyc.tierUpgradeStatus,
      tierUpgradeReviewNotes: kyc.tierUpgradeReviewNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'bvn': bvn,
      'nin': nin,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isBvnVerified': isBvnVerified,
      'isAddressVerified': isAddressVerified,
      'isSelfieVerified': isSelfieVerified,
      'isDocumentVerified': isDocumentVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'selectedTier': selectedTier,
      'kycStatus': kycStatus.wireValue,
      'idDocumentStatus': idDocumentStatus.wireValue,
      'addressStatus': addressStatus.wireValue,
      'requiresManualReview': requiresManualReview,
      'isNinVerified': isNinVerified,
      'userStatus': userStatus?.wireValue,
      'registrationComplete': registrationComplete,
      'pendingTier': pendingTier,
      'grantedTier': grantedTier,
      'rejectionReason': rejectionReason,
      'idDocumentRejectionReason': idDocumentRejectionReason,
      'addressRejectionReason': addressRejectionReason,
      'tierUpgradeStatus': tierUpgradeStatus?.wireValue,
      'tierUpgradeReviewNotes': tierUpgradeReviewNotes,
    };
  }

  /// Builds a [UserModel] from kudikit_auth_service's `UserResponse` shape
  /// (the `data.user` object of an AuthTokenResponse — same for /auth/login,
  /// /auth/register, /auth/login/verify-device and /auth/refresh-token). This
  /// is deliberately separate from [fromJson] (which round-trips the app's own
  /// local-storage shape) because the two field sets genuinely differ: the
  /// server has no concept of this app's local `userId`/verification-flag
  /// fields, and this app has no local concept of the server's
  /// `tier`/`status`/`registrationComplete`.
  ///
  /// [existing], when supplied (refresh path), merges the server's
  /// authoritative identity/tier/KYC fields over the cached model while
  /// preserving locally-held KYC state ONLY when the server sends no KYC
  /// summary (`user.kyc` absent). When `user.kyc` IS present, the server wins
  /// wholesale (Slice 4B): typed enums and the convenience booleans are both
  /// derived from it — stale cached booleans are never preserved over server
  /// KYC data.
  factory UserModel.fromAuthResponse(
    Map<String, dynamic> json, {
    UserModel? existing,
  }) {
    final Map<String, dynamic>? kycJson = json['kyc'] as Map<String, dynamic>?;
    final KycStatusSummary serverKyc = kycJson == null
        ? KycStatusSummary()
        : KycStatusSummary.fromJson(kycJson);
    final bool hasServerKyc = kycJson != null;
    return UserModel(
      userId: (json['customerId'] as String?) ?? existing?.userId ?? '',
      email: (json['email'] as String?) ?? existing?.email ?? '',
      phoneNumber:
          (json['phoneNumber'] as String?) ?? existing?.phoneNumber ?? '',
      name: json['fullName'] as String? ?? existing?.name,
      // A successful register/login response means the identity behind this
      // account was already OTP-verified — this app has no separate signal
      // for "verified" beyond that.
      isEmailVerified: true,
      isPhoneVerified: true,
      // KYC booleans: server KYC present → derived from it (authoritative);
      // server KYC absent → preserve cached flags so a silent token refresh
      // never resets KYC progress.
      isBvnVerified: hasServerKyc ? serverKyc.bvnVerified : (existing?.isBvnVerified ?? false),
      isAddressVerified: hasServerKyc
          ? serverKyc.addressStatus == AddressVerificationStatus.verified
          : (existing?.isAddressVerified ?? false),
      isSelfieVerified: hasServerKyc
          ? serverKyc.livenessVerified
          : (existing?.isSelfieVerified ?? false),
      isDocumentVerified: hasServerKyc
          ? serverKyc.idDocumentStatus == IdDocumentStatus.verified
          : (existing?.isDocumentVerified ?? false),
      bvn: existing?.bvn,
      nin: existing?.nin,
      createdAt: existing?.createdAt,
      lastLogin: DateTime.now(),
      selectedTier: _tierStringToInt(json['tier'] as String?),
      // Server-authoritative typed KYC state (Slice 4B).
      kycStatus: hasServerKyc ? serverKyc.status : (existing?.kycStatus ?? KycStatus.notStarted),
      idDocumentStatus: hasServerKyc
          ? serverKyc.idDocumentStatus
          : (existing?.idDocumentStatus ?? IdDocumentStatus.notStarted),
      addressStatus: hasServerKyc
          ? serverKyc.addressStatus
          : (existing?.addressStatus ?? AddressVerificationStatus.notStarted),
      requiresManualReview: hasServerKyc
          ? serverKyc.requiresManualReview
          : (existing?.requiresManualReview ?? false),
      isNinVerified: hasServerKyc ? serverKyc.ninVerified : (existing?.isNinVerified ?? false),
      userStatus: json['status'] is String
          ? UserStatus.fromWire(json['status'] as String)
          : existing?.userStatus,
      registrationComplete: (json['registrationComplete'] as bool?) ??
          (existing?.registrationComplete ?? false),
      pendingTier: _tierStringToIntNullable(json['pendingTier']),
      // SLICE 7 P0-3: the granted tier is the server's `tier` claim. null must
      // stay null (UNVERIFIED) — it must NOT be fabricated into Basic/Tier 1.
      grantedTier: _tierStringToIntNullable(json['tier']),
      rejectionReason: json['rejectionReason'] as String?,
      // Tier-upgrade lifecycle (backend MEGA review gate): server wins when the
      // KYC summary is present; preserved from cache otherwise.
      tierUpgradeStatus: hasServerKyc
          ? serverKyc.tierUpgradeStatus
          : existing?.tierUpgradeStatus,
      tierUpgradeReviewNotes: hasServerKyc
          ? serverKyc.tierUpgradeReviewNotes
          : existing?.tierUpgradeReviewNotes,
      idDocumentRejectionReason: json['idDocumentRejectionReason'] as String?,
      addressRejectionReason: json['addressRejectionReason'] as String?,
    );
  }

  static int? _tierStringToIntNullable(Object? tier) {
    if (tier == null) return null;
    if (tier is int) return tier;
    if (tier is String) return _tierStringToInt(tier);
    return null;
  }

  static int _tierStringToInt(String? tier) {
    switch (tier) {
      case 'PRO':
        return 2;
      case 'MEGA':
        return 3;
      case 'BASIC':
      default:
        return 1;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      bvn: json['bvn'] as String?,
      nin: json['nin'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      isBvnVerified: json['isBvnVerified'] as bool? ?? false,
      isAddressVerified: json['isAddressVerified'] as bool? ?? false,
      isSelfieVerified: json['isSelfieVerified'] as bool? ?? false,
      isDocumentVerified: json['isDocumentVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      selectedTier: (json['selectedTier'] as int?) ?? (json['tier'] as int?) ?? 1,
      kycStatus: KycStatus.fromWire(json['kycStatus']),
      idDocumentStatus: IdDocumentStatus.fromWire(json['idDocumentStatus']),
      addressStatus: AddressVerificationStatus.fromWire(json['addressStatus']),
      requiresManualReview: json['requiresManualReview'] as bool? ?? false,
      isNinVerified: json['isNinVerified'] as bool? ?? false,
      userStatus: json['userStatus'] is String
          ? UserStatus.fromWire(json['userStatus'] as String)
          : null,
      registrationComplete: json['registrationComplete'] as bool? ?? false,
      pendingTier: _tierStringToIntNullable(json['pendingTier']),
      grantedTier:
          _tierStringToIntNullable(json['grantedTier'] ?? json['tier']),
      rejectionReason: json['rejectionReason'] as String?,
      idDocumentRejectionReason: json['idDocumentRejectionReason'] as String?,
      addressRejectionReason: json['addressRejectionReason'] as String?,
      tierUpgradeStatus:
          TierUpgradeStatus.fromWire(json['tierUpgradeStatus'] as String?),
      tierUpgradeReviewNotes: json['tierUpgradeReviewNotes'] as String?,
    );
  }
}