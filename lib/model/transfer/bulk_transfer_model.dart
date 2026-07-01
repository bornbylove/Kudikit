import 'package:flutter/material.dart';

enum TransferAccountType {
  kudikit,
  bank,
}

enum AmountDistributionType {
  soloAmount, // Each recipient gets individual amounts
  equalSplit, // Total amount split equally
}

class BulkTransferRecipient {
  final String id;
  final String name;
  final TransferAccountType accountType;
  final String accountNumber;
  final String? bankName;
  final String? bankCode;
  final String? phoneNumber;
  final String? narration;
  final double? amount; // For solo amount mode
  final bool isVerified;

  BulkTransferRecipient({
    required this.id,
    required this.name,
    required this.accountType,
    required this.accountNumber,
    this.bankName,
    this.bankCode,
    this.phoneNumber,
    this.narration,
    this.amount,
    this.isVerified = false,
  });

  BulkTransferRecipient copyWith({
    String? id,
    String? name,
    TransferAccountType? accountType,
    String? accountNumber,
    String? bankName,
    String? bankCode,
    String? phoneNumber,
    String? narration,
    double? amount,
    bool? isVerified,
  }) {
    return BulkTransferRecipient(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      narration: narration ?? this.narration,
      amount: amount ?? this.amount,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType':
          accountType == TransferAccountType.kudikit ? 'kudikit' : 'bank',
      'accountNumber': accountNumber,
      'bankName': bankName,
      'bankCode': bankCode,
      'phoneNumber': phoneNumber,
      'narration': narration,
      'amount': amount,
      'isVerified': isVerified,
    };
  }

  factory BulkTransferRecipient.fromJson(Map<String, dynamic> json) {
    return BulkTransferRecipient(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] == 'kudikit'
          ? TransferAccountType.kudikit
          : TransferAccountType.bank,
      accountNumber: json['accountNumber'] as String,
      bankName: json['bankName'] as String?,
      bankCode: json['bankCode'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      narration: json['narration'] as String?,
      amount: json['amount'] as double?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class BulkTransferTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<BulkTransferRecipient> recipients;
  final int useCount;

  BulkTransferTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.recipients,
    this.useCount = 0,
  });

  BulkTransferTemplate copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<BulkTransferRecipient>? recipients,
    int? useCount,
  }) {
    return BulkTransferTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      recipients: recipients ?? this.recipients,
      useCount: useCount ?? this.useCount,
    );
  }

  factory BulkTransferTemplate.fromJson(Map<String, dynamic> json) {
    final rawRecipients = json['recipients'] as List<dynamic>? ?? [];
    return BulkTransferTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      useCount: json['use_count'] as int? ?? 0,
      recipients: rawRecipients
          .map((r) => BulkTransferRecipient.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'use_count': useCount,
        'recipients': recipients.map((r) => r.toJson()).toList(),
      };
}

class BulkTransferState {
  final List<BulkTransferRecipient> recipients;
  final AmountDistributionType distributionType;
  final double? totalAmount;
  final double? amountPerRecipient;
  final bool isScheduled;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final double bankTransferFees;
  final bool isLoading;
  final String? error;

  BulkTransferState({
    this.recipients = const [],
    this.distributionType = AmountDistributionType.equalSplit,
    this.totalAmount,
    this.amountPerRecipient,
    this.isScheduled = false,
    this.scheduledDate,
    this.scheduledTime,
    this.bankTransferFees = 0.0,
    this.isLoading = false,
    this.error,
  });

  int get recipientCount => recipients.length;

  int get kudikitRecipientCount => recipients
      .where((r) => r.accountType == TransferAccountType.kudikit)
      .length;

  int get bankRecipientCount =>
      recipients.where((r) => r.accountType == TransferAccountType.bank).length;

  double get calculatedTotalAmount {
    if (distributionType == AmountDistributionType.soloAmount) {
      return recipients.fold(0.0, (sum, r) => sum + (r.amount ?? 0.0));
    } else {
      return (amountPerRecipient ?? 0.0) * recipients.length;
    }
  }

  double get totalBankFees {
    // ₦10 per bank recipient as per the design
    return bankRecipientCount * 10.0;
  }

  double get totalDebit {
    return calculatedTotalAmount + totalBankFees;
  }

  bool get isValid {
    if (recipients.isEmpty) return false;

    if (distributionType == AmountDistributionType.soloAmount) {
      return recipients.every((r) => r.amount != null && r.amount! > 0);
    } else {
      return amountPerRecipient != null && amountPerRecipient! > 0;
    }
  }

  BulkTransferState copyWith({
    List<BulkTransferRecipient>? recipients,
    AmountDistributionType? distributionType,
    double? totalAmount,
    double? amountPerRecipient,
    bool? isScheduled,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    double? bankTransferFees,
    bool? isLoading,
    String? error,
  }) {
    return BulkTransferState(
      recipients: recipients ?? this.recipients,
      distributionType: distributionType ?? this.distributionType,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPerRecipient: amountPerRecipient ?? this.amountPerRecipient,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      bankTransferFees: bankTransferFees ?? this.bankTransferFees,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
