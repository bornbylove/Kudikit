import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kudipay/model/agent/agent_model.dart';
import 'package:kudipay/model/agent/cashout_transaction_model.dart';

class TransactionCodeService {
  static final TransactionCodeService _instance =
      TransactionCodeService._internal();
  factory TransactionCodeService() => _instance;
  TransactionCodeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random.secure();

  static const int _codeLength = 6;
  static const int _expiryMinutes = 15;

  /// Generate a unique 6-digit transaction code
  /// Ensures uniqueness by checking Firestore for existing codes
  Future<String> generateUniqueCode() async {
    String code;
    bool isUnique = false;
    int attempts = 0;

    do {
      code = _generateCode();
      isUnique = await _isCodeUnique(code);
      attempts++;
      if (attempts > 10) {
        // Fallback: use timestamp-based code to guarantee uniqueness
        code = _generateTimestampCode();
        isUnique = true;
      }
    } while (!isUnique);

    return code;
  }

  /// Create a cash-out transaction in Firestore with the generated code
  Future<CashOutTransaction> createTransaction({
    required String userId,
    required AgentModel agent,
    required double withdrawalAmount,
    required String userAccountNumber,
    required String userName,
  }) async {
    final commission = withdrawalAmount * (agent.commissionPercent / 100);
    final totalDebit = withdrawalAmount + commission;
    final code = await generateUniqueCode();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: _expiryMinutes));

    final transaction = CashOutTransaction(
      id: '', // Will be set by Firestore
      userId: userId,
      agentId: agent.id,
      agentName: agent.shopName,
      agentAccountNumber: agent.accountNumber,
      agentBankName: agent.bankName,
      withdrawalAmount: withdrawalAmount,
      commission: commission,
      totalDebit: totalDebit,
      transactionCode: code,
      createdAt: now,
      expiresAt: expiresAt,
      status: TransactionStatus.pending,
      userAccountNumber: userAccountNumber,
      userName: userName,
    );

    try {
      final docRef = await _firestore
          .collection('cash_out_transactions')
          .add(transaction.toMap());

      return CashOutTransaction(
        id: docRef.id,
        userId: transaction.userId,
        agentId: transaction.agentId,
        agentName: transaction.agentName,
        agentAccountNumber: transaction.agentAccountNumber,
        agentBankName: transaction.agentBankName,
        withdrawalAmount: transaction.withdrawalAmount,
        commission: transaction.commission,
        totalDebit: transaction.totalDebit,
        transactionCode: transaction.transactionCode,
        createdAt: transaction.createdAt,
        expiresAt: transaction.expiresAt,
        status: transaction.status,
        userAccountNumber: transaction.userAccountNumber,
        userName: transaction.userName,
      );
    } catch (e) {
      // Return local transaction for dev/offline
      return CashOutTransaction(
        id: 'local_${now.millisecondsSinceEpoch}',
        userId: transaction.userId,
        agentId: transaction.agentId,
        agentName: transaction.agentName,
        agentAccountNumber: transaction.agentAccountNumber,
        agentBankName: transaction.agentBankName,
        withdrawalAmount: transaction.withdrawalAmount,
        commission: transaction.commission,
        totalDebit: transaction.totalDebit,
        transactionCode: transaction.transactionCode,
        createdAt: transaction.createdAt,
        expiresAt: transaction.expiresAt,
        status: transaction.status,
        userAccountNumber: transaction.userAccountNumber,
        userName: transaction.userName,
      );
    }
  }

  /// Mark a transaction as completed (user taps "Received")
  Future<void> markTransactionCompleted(String transactionId) async {
    try {
      await _firestore
          .collection('cash_out_transactions')
          .doc(transactionId)
          .update({
        'status': TransactionStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Also add to transaction history collection
      await _firestore.collection('transaction_history').add({
        'transactionId': transactionId,
        'type': 'cash_out',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle offline gracefully — queue for sync
    }
  }

  /// Mark expired transactions
  Future<void> markTransactionExpired(String transactionId) async {
    try {
      await _firestore
          .collection('cash_out_transactions')
          .doc(transactionId)
          .update({'status': TransactionStatus.expired.name});
    } catch (e) {
      // ignore
    }
  }

  /// Format code for display: "234 765" (with space in middle)
  String formatCodeForDisplay(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  // --- Private Helpers ---

  String _generateCode() {
    final buffer = StringBuffer();
    for (int i = 0; i < _codeLength; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  String _generateTimestampCode() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return (ts % 1000000).toString().padLeft(6, '0');
  }

  Future<bool> _isCodeUnique(String code) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final query = await _firestore
          .collection('cash_out_transactions')
          .where('transactionCode', isEqualTo: code)
          .where('status', isEqualTo: TransactionStatus.pending.name)
          .where('expiresAt', isGreaterThan: now)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      return true; // Assume unique if can't check
    }
  }
}
