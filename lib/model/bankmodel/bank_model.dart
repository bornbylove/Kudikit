import 'package:flutter/foundation.dart';

@immutable
class Bank {
  final String id;
  final String name;
  final String code;
  final String logo;
  final String ussdCode;
  final bool isActive;

  const Bank({
    required this.id,
    required this.name,
    required this.code,
    required this.logo,
    required this.ussdCode,
    this.isActive = true,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      logo: json['logo'] as String,
      ussdCode: json['ussd_code'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'logo': logo,
      'ussd_code': ussdCode,
      'is_active': isActive,
    };
  }

  Bank copyWith({
    String? id,
    String? name,
    String? code,
    String? logo,
    String? ussdCode,
    bool? isActive,
  }) {
    return Bank(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      logo: logo ?? this.logo,
      ussdCode: ussdCode ?? this.ussdCode,
      isActive: isActive ?? this.isActive,
    );
  }
}

@immutable
class CardTopUpRequest {
  final double amount;
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String pin;

  const CardTopUpRequest({
    required this.amount,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'card_number': cardNumber,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'pin': pin,
    };
  }
}

@immutable
class CardTopUpResponse {
  final bool success;
  final String message;
  final String? transactionId;
  final String? reference;
  final bool requiresOtp;
  final String? otpReference;

  const CardTopUpResponse({
    required this.success,
    required this.message,
    this.transactionId,
    this.reference,
    this.requiresOtp = false,
    this.otpReference,
  });

  factory CardTopUpResponse.fromJson(Map<String, dynamic> json) {
    return CardTopUpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      transactionId: json['transaction_id'] as String?,
      reference: json['reference'] as String?,
      requiresOtp: json['requires_otp'] as bool? ?? false,
      otpReference: json['otp_reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (transactionId != null) 'transaction_id': transactionId,
      if (reference != null) 'reference': reference,
      'requires_otp': requiresOtp,
      if (otpReference != null) 'otp_reference': otpReference,
    };
  }
}

@immutable
class TransactionReceipt {
  final String transactionType;
  final double amount;
  final String status;
  final String payingBank;
  final String creditedTo;
  final String transactionNumber;
  final DateTime transactionDate;

  const TransactionReceipt({
    required this.transactionType,
    required this.amount,
    required this.status,
    required this.payingBank,
    required this.creditedTo,
    required this.transactionNumber,
    required this.transactionDate,
  });

  factory TransactionReceipt.fromJson(Map<String, dynamic> json) {
    return TransactionReceipt(
      transactionType: json['transaction_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      payingBank: json['paying_bank'] as String,
      creditedTo: json['credited_to'] as String,
      transactionNumber: json['transaction_number'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_type': transactionType,
      'amount': amount,
      'status': status,
      'paying_bank': payingBank,
      'credited_to': creditedTo,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }
}

@immutable
class UssdTransferData {
  final Bank bank;
  final double amount;
  final String ussdCode;
  final String accountNumber;
  final Duration timeRemaining;

  const UssdTransferData({
    required this.bank,
    required this.amount,
    required this.ussdCode,
    required this.accountNumber,
    required this.timeRemaining,
  });

  UssdTransferData copyWith({
    Bank? bank,
    double? amount,
    String? ussdCode,
    String? accountNumber,
    Duration? timeRemaining,
  }) {
    return UssdTransferData(
      bank: bank ?? this.bank,
      amount: amount ?? this.amount,
      ussdCode: ussdCode ?? this.ussdCode,
      accountNumber: accountNumber ?? this.accountNumber,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }
}
