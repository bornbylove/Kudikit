// lib/features/transfer/domain/repositories/transfer_repository.dart

import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/features/transfer/domain/entities/bulk_transfer_model.dart';

abstract interface class TransferRepository {
  /// Validates an account number and returns recipient info.
  Future<RecipientEntity> validateAccount({
    required String accountNumber,
    required TransferType type,
  });

  /// Returns recent transfer contacts.
  Future<List<RecentContactEntity>> getRecentContacts();

  /// Executes a single P2P transfer.
  Future<TransferResultEntity> processTransfer({
    required RecipientEntity recipient,
    required double amount,
    required String pin,
    TransactionCategory? category,
    String? note,
  });

  /// Executes a bulk transfer.
  Future<void> executeBulkTransfer({
    required List<BulkTransferRecipient> recipients,
    required double totalAmount,
    required AmountDistributionType distributionType,
    String? pin,
    DateTime? scheduledAt,
  });

  /// Fetches saved bulk transfer templates.
  Future<List<BulkTransferTemplate>> getBulkTransferTemplates();
}
