import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, completed, expired, cancelled }

class CashOutTransaction {
  final String id;
  final String userId;
  final String agentId;
  final String agentName;
  final String agentAccountNumber;
  final String agentBankName;
  final double withdrawalAmount;
  final double commission;
  final double totalDebit;
  final String transactionCode; // 6-digit unique code
  final DateTime createdAt;
  final DateTime expiresAt; // 15 minutes after creation
  final TransactionStatus status;
  final String userAccountNumber;
  final String userName;

  CashOutTransaction({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.agentName,
    required this.agentAccountNumber,
    required this.agentBankName,
    required this.withdrawalAmount,
    required this.commission,
    required this.totalDebit,
    required this.transactionCode,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.userAccountNumber,
    required this.userName,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  factory CashOutTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CashOutTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? '',
      agentAccountNumber: data['agentAccountNumber'] ?? '',
      agentBankName: data['agentBankName'] ?? '',
      withdrawalAmount: (data['withdrawalAmount'] ?? 0.0).toDouble(),
      commission: (data['commission'] ?? 0.0).toDouble(),
      totalDebit: (data['totalDebit'] ?? 0.0).toDouble(),
      transactionCode: data['transactionCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      userAccountNumber: data['userAccountNumber'] ?? '',
      userName: data['userName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'agentAccountNumber': agentAccountNumber,
      'agentBankName': agentBankName,
      'withdrawalAmount': withdrawalAmount,
      'commission': commission,
      'totalDebit': totalDebit,
      'transactionCode': transactionCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.name,
      'userAccountNumber': userAccountNumber,
      'userName': userName,
      'type': 'cash_out',
    };
  }

  CashOutTransaction copyWith({TransactionStatus? status}) {
    return CashOutTransaction(
      id: id,
      userId: userId,
      agentId: agentId,
      agentName: agentName,
      agentAccountNumber: agentAccountNumber,
      agentBankName: agentBankName,
      withdrawalAmount: withdrawalAmount,
      commission: commission,
      totalDebit: totalDebit,
      transactionCode: transactionCode,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
      userAccountNumber: userAccountNumber,
      userName: userName,
    );
  }
}
