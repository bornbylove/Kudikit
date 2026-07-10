import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { draft, submitted, underReview, approved, rejected }

enum BusinessType {
  posAgent('POS Agent'),
  supermarket('Supermarket'),
  pharmacy('Pharmacy'),
  kiosk('Kiosk'),
  miniMart('Mini Mart'),
  fuelStation('Fuel Station'),
  other('Other');

  final String label;
  const BusinessType(this.label);
}

class AgentApplication {
  // Step 1 — Business Info
  final String businessName;
  final BusinessType? businessType;
  final String businessDescription;

  // Step 2 — Location
  final String businessAddress;
  final String storefrontPhotoUrl;

  // Step 3 — Operating Setup
  final List<String> operatingDays;
  final String openingTime;
  final String closingTime;
  final double cashFloat;
  final double minPerTransaction;
  final double maxPerTransaction;
  final double commissionRate;

  // Step 4 — Bank Account
  final String bankName;
  final String accountNumber;
  final String accountName;

  // Meta
  final ApplicationStatus status;
  final String userId;
  final DateTime? submittedAt;

  const AgentApplication({
    this.businessName = '',
    this.businessType,
    this.businessDescription = '',
    this.businessAddress = '',
    this.storefrontPhotoUrl = '',
    this.operatingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.openingTime = '8:00 AM',
    this.closingTime = '9:00 PM',
    this.cashFloat = 0,
    this.minPerTransaction = 0,
    this.maxPerTransaction = 0,
    this.commissionRate = 1.5,
    this.bankName = 'Kudikit',
    this.accountNumber = '',
    this.accountName = '',
    this.status = ApplicationStatus.draft,
    this.userId = '',
    this.submittedAt,
  });

  // ── Validation ────────────────────────────────────────────────────────────

  bool get isStep1Valid =>
      businessName.trim().isNotEmpty && businessType != null;

  bool get isStep2Valid => businessAddress.trim().isNotEmpty;

  bool get isStep3Valid =>
      operatingDays.isNotEmpty &&
      cashFloat > 0 &&
      minPerTransaction > 0 &&
      maxPerTransaction >= minPerTransaction;

  bool get isStep4Valid =>
      accountNumber.trim().length == 10 && accountName.trim().isNotEmpty;

  bool get isFullyValid =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

  // ── Earning estimates ─────────────────────────────────────────────────────

  double get estimatedPerWithdrawal =>
      ((minPerTransaction + maxPerTransaction) / 2) * (commissionRate / 100);

  double get estimatedDaily => estimatedPerWithdrawal * 10;

  double get estimatedMonthly => estimatedDaily * 22;

  // ── CopyWith ──────────────────────────────────────────────────────────────

  AgentApplication copyWith({
    String? businessName,
    BusinessType? businessType,
    String? businessDescription,
    String? businessAddress,
    String? storefrontPhotoUrl,
    List<String>? operatingDays,
    String? openingTime,
    String? closingTime,
    double? cashFloat,
    double? minPerTransaction,
    double? maxPerTransaction,
    double? commissionRate,
    String? bankName,
    String? accountNumber,
    String? accountName,
    ApplicationStatus? status,
    String? userId,
    DateTime? submittedAt,
  }) {
    return AgentApplication(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessDescription: businessDescription ?? this.businessDescription,
      businessAddress: businessAddress ?? this.businessAddress,
      storefrontPhotoUrl: storefrontPhotoUrl ?? this.storefrontPhotoUrl,
      operatingDays: operatingDays ?? this.operatingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      cashFloat: cashFloat ?? this.cashFloat,
      minPerTransaction: minPerTransaction ?? this.minPerTransaction,
      maxPerTransaction: maxPerTransaction ?? this.maxPerTransaction,
      commissionRate: commissionRate ?? this.commissionRate,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'businessType': businessType?.name,
        'businessDescription': businessDescription,
        'businessAddress': businessAddress,
        'storefrontPhotoUrl': storefrontPhotoUrl,
        'operatingDays': operatingDays,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'cashFloat': cashFloat,
        'minPerTransaction': minPerTransaction,
        'maxPerTransaction': maxPerTransaction,
        'commissionRate': commissionRate,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'status': status.name,
        'userId': userId,
        'submittedAt':
            submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      };
}
