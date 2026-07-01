// lib/features/transfer/domain/entities/transfer_entities.dart
//
// Pure Dart domain entities for both single (P2P) and bulk transfers.

// =============================================================================
// Shared enums
// =============================================================================

enum TransferType { kudikit, otherBank }

enum TransactionCategory {
  food,
  transport,
  bills,
  shopping,
  entertainment,
  others,
}

// =============================================================================
// Single transfer entities
// =============================================================================

class RecipientEntity {
  final String accountNumber;
  final String name;
  final String? bank;
  final String? bankCode;
  final String? avatarUrl;

  const RecipientEntity({
    required this.accountNumber,
    required this.name,
    this.bank,
    this.bankCode,
    this.avatarUrl,
  });

  RecipientEntity copyWith({
    String? accountNumber,
    String? name,
    String? bank,
    String? bankCode,
    String? avatarUrl,
  }) =>
      RecipientEntity(
        accountNumber: accountNumber ?? this.accountNumber,
        name: name ?? this.name,
        bank: bank ?? this.bank,
        bankCode: bankCode ?? this.bankCode,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

class RecentContactEntity {
  final String id;
  final String name;
  final String accountNumber;
  final String bank;
  final String? avatarUrl;
  final DateTime lastTransferDate;

  const RecentContactEntity({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bank,
    this.avatarUrl,
    required this.lastTransferDate,
  });
}

class TransferResultEntity {
  final String transactionId;
  final String transactionType;
  final double amount;
  final double fee;
  final String payingBank;
  final String payingBankAccount;
  final String creditedTo;
  final String? note;
  final DateTime transactionDate;
  final bool isSuccessful;

  const TransferResultEntity({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    required this.fee,
    required this.payingBank,
    required this.payingBankAccount,
    required this.creditedTo,
    this.note,
    required this.transactionDate,
    this.isSuccessful = true,
  });
}
