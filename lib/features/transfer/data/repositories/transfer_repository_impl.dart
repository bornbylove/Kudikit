// lib/features/transfer/data/repositories/transfer_repository_impl.dart

import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/features/transfer/domain/entities/bank_entity.dart';
import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:kudipay/features/transfer/domain/entities/bulk_transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final DioClient _client;
  const TransferRepositoryImpl(this._client);

  @override
  Future<List<Bank>> getBanks() async {
    // WARNING: this reads data.banks, while WalletRemoteDataSource.getBanks
    // reads the response body as a bare array from the SAME endpoint. Both
    // cannot be correct — one of them has been failing silently. Preserved
    // as-is here to avoid changing behaviour during the layer move; needs the
    // real /banks contract to resolve.
    final res = await _client.get<Map<String, dynamic>>('/banks');
    final raw = (res.data?['banks'] as List<dynamic>?) ?? const [];
    return raw.map((b) => Bank.fromJson(b as Map<String, dynamic>)).toList();
  }

  @override
  Future<RecipientEntity> validateAccount({
    required String accountNumber,
    required TransferType type,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/transfer/validate-account',
      data: {'account_number': accountNumber},
    );
    final data = res.data!;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Account not found');
    }
    return RecipientEntity(
      accountNumber: data['account_number'] as String,
      name: data['account_name'] as String,
      bank: data['bank_name'] as String?,
    );
  }

  @override
  Future<List<RecentContactEntity>> getRecentContacts() async {
    final res =
        await _client.get<Map<String, dynamic>>('/transfer/recent-contacts');
    final raw = res.data!['contacts'] as List<dynamic>;
    return raw.map((c) {
      final m = c as Map<String, dynamic>;
      return RecentContactEntity(
        id: m['id'] as String,
        name: m['name'] as String,
        accountNumber: m['account_number'] as String,
        bank: m['bank_name'] as String,
        lastTransferDate: DateTime.parse(m['last_transfer_date'] as String),
      );
    }).toList();
  }

  @override
  Future<TransferResultEntity> processTransfer({
    required RecipientEntity recipient,
    required double amount,
    required String pin,
    TransactionCategory? category,
    String? note,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/transfer/execute',
      data: {
        'account_number': recipient.accountNumber,
        'amount': amount,
        'pin': pin,
        if (note != null) 'narration': note,
        if (category != null) 'category': category.name,
      },
    );
    final result = res.data!;
    return TransferResultEntity(
      transactionId: result['transaction_id'] as String,
      transactionType: result['transaction_type'] as String,
      amount: (result['amount'] as num).toDouble(),
      fee: (result['fee'] as num?)?.toDouble() ?? 0,
      payingBank: result['paying_bank'] as String,
      payingBankAccount: result['paying_bank_account'] as String,
      creditedTo: result['credited_to'] as String,
      note: note,
      transactionDate: DateTime.now(),
      isSuccessful: result['status'] == 'successful',
    );
  }

  @override
  Future<void> executeBulkTransfer({
    required List<BulkTransferRecipient> recipients,
    required double totalAmount,
    required AmountDistributionType distributionType,
    String? pin,
    DateTime? scheduledAt,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/transfer/bulk/execute',
      data: {
        'recipients': recipients.map((r) => r.toJson()).toList(),
        'total_amount': totalAmount,
        'distribution_type': distributionType.name,
        if (pin != null) 'pin': pin,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      },
    );
    final result = res.data!;
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Bulk transfer failed');
    }
  }

  @override
  Future<List<BulkTransferTemplate>> getBulkTransferTemplates() async {
    try {
      final res =
          await _client.get<Map<String, dynamic>>('/transfer/bulk/templates');
      final raw = res.data!['templates'] as List<dynamic>;
      return raw
          .map((t) => BulkTransferTemplate.fromJson(t as Map<String, dynamic>))
          .toList();
    } on KudiApiException {
      return [];
    }
  }
}
