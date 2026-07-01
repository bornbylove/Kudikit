// lib/model/transaction/transaction_model.dart
// FIXED:
//   - Added `title` field (API returns 'title', was mapped to 'description')
//   - Added `formattedDate` getter (used by HomeScreen transaction list)
//   - Added `formattedAmount` getter (used by HomeScreen transaction list)
//   - fromJson now reads both 'title' and 'description' keys for compatibility
//   - TransactionStatus.value string matches API response ('successful' not 'Successful')

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class Transaction {
  final String id;
  final String title; // display name, e.g. "Transfer to TEMI OLUWA"
  final String description; // kept for backward compat — same as title
  final DateTime date;
  final double amount;
  final TransactionStatus status;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // API may send 'title' or 'description' — accept both
    final titleVal = (json['title'] ?? json['description'] ?? '') as String;
    return Transaction(
      id: json['id'] as String,
      title: titleVal,
      description: titleVal,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: TransactionStatus.fromString(json['status'] as String),
      type: TransactionType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'amount': amount,
        'status': status.value,
        'type': type.value,
      };

  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    double? amount,
    TransactionStatus? status,
    TransactionType? type,
  }) =>
      Transaction(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        status: status ?? this.status,
        type: type ?? this.type,
      );

  // ── Display helpers used by HomeScreen & TransactionScreen ───────────────

  /// Human-readable date: "Dec 20th, 10:39:25"
  String get formattedDate {
    final day = date.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';
    final month = DateFormat('MMM').format(date);
    final time = DateFormat('HH:mm:ss').format(date);
    return '$month $day$suffix, $time';
  }

  /// Currency string with sign: "-₦10,200.00" or "+₦50,000.00"
  String get formattedAmount {
    final fmt = NumberFormat('#,##0.00', 'en_NG');
    final sign = type == TransactionType.debit ? '-' : '+';
    return '$sign₦${fmt.format(amount)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Transaction && id == other.id);

  @override
  int get hashCode => id.hashCode;
}

// ── TransactionStatus ─────────────────────────────────────────────────────────
enum TransactionStatus {
  successful('successful'),
  failed('failed'),
  pending('pending');

  final String value;
  const TransactionStatus(this.value);

  static TransactionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'success':
        return TransactionStatus.successful;
      case 'failed':
      case 'fail':
        return TransactionStatus.failed;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }
}

// ── TransactionType ───────────────────────────────────────────────────────────
enum TransactionType {
  debit('debit'),
  credit('credit');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
      default:
        return TransactionType.debit;
    }
  }
}
