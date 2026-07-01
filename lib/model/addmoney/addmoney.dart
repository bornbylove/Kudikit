import 'package:flutter/foundation.dart';

@immutable
class AddMoneyOption {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final AddMoneyType type;

  const AddMoneyOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });

  factory AddMoneyOption.fromJson(Map<String, dynamic> json) {
    return AddMoneyOption(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      icon: json['icon'] as String,
      type: AddMoneyType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'type': type.value,
    };
  }
}

enum AddMoneyType {
  bankTransfer('bank_transfer'),
  cashDeposit('cash_deposit'),
  cardTopUp('card_topup'),
  ussdTransfer('ussd_transfer'),
  qrCode('qr_code');

  final String value;
  const AddMoneyType(this.value);

  static AddMoneyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bank_transfer':
        return AddMoneyType.bankTransfer;
      case 'cash_deposit':
        return AddMoneyType.cashDeposit;
      case 'card_topup':
        return AddMoneyType.cardTopUp;
      case 'ussd_transfer':
        return AddMoneyType.ussdTransfer;
      case 'qr_code':
        return AddMoneyType.qrCode;
      default:
        return AddMoneyType.bankTransfer;
    }
  }
}

@immutable
class AccountDetails {
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String? referenceCode;

  const AccountDetails({
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    this.referenceCode,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      accountNumber: json['account_number'] as String,
      accountName: json['account_name'] as String,
      bankName: json['bank_name'] as String,
      referenceCode: json['reference_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'account_name': accountName,
      'bank_name': bankName,
      if (referenceCode != null) 'reference_code': referenceCode,
    };
  }
}

@immutable
class AddMoneyResponse {
  final bool success;
  final String message;
  final AccountDetails? accountDetails;
  final String? qrCodeUrl;
  final String? ussdCode;

  const AddMoneyResponse({
    required this.success,
    required this.message,
    this.accountDetails,
    this.qrCodeUrl,
    this.ussdCode,
  });

  factory AddMoneyResponse.fromJson(Map<String, dynamic> json) {
    return AddMoneyResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      accountDetails: json['account_details'] != null
          ? AccountDetails.fromJson(
              json['account_details'] as Map<String, dynamic>)
          : null,
      qrCodeUrl: json['qr_code_url'] as String?,
      ussdCode: json['ussd_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (accountDetails != null) 'account_details': accountDetails!.toJson(),
      if (qrCodeUrl != null) 'qr_code_url': qrCodeUrl,
      if (ussdCode != null) 'ussd_code': ussdCode,
    };
  }
}
