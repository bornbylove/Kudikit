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
  });

  // Check if KYC is complete
  bool get isKycComplete =>
      isEmailVerified &&
      isBvnVerified &&
      isAddressVerified &&
      isSelfieVerified &&
      isDocumentVerified;

  // Get KYC completion percentage
  double get kycProgress {
    int completed = 0;
    if (isEmailVerified) completed++;
    if (isBvnVerified) completed++;
    if (isAddressVerified) completed++;
    if (isSelfieVerified) completed++;
    if (isDocumentVerified) completed++;
    return completed / 5.0;
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
    };
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
      selectedTier:
          (json['selectedTier'] as int?) ?? (json['tier'] as int?) ?? 1,
    );
  }
}
