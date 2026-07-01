// lib/features/transfer/domain/usecases/transfer_usecases.dart

import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';

class ValidateAccountUseCase {
  final TransferRepository _repository;
  const ValidateAccountUseCase(this._repository);

  Future<RecipientEntity> call({
    required String accountNumber,
    required TransferType type,
  }) =>
      _repository.validateAccount(accountNumber: accountNumber, type: type);
}

class GetRecentContactsUseCase {
  final TransferRepository _repository;
  const GetRecentContactsUseCase(this._repository);

  Future<List<RecentContactEntity>> call() => _repository.getRecentContacts();
}

class ProcessTransferUseCase {
  final TransferRepository _repository;
  const ProcessTransferUseCase(this._repository);

  Future<TransferResultEntity> call({
    required RecipientEntity recipient,
    required double amount,
    required String pin,
    TransactionCategory? category,
    String? note,
  }) =>
      _repository.processTransfer(
        recipient: recipient,
        amount: amount,
        pin: pin,
        category: category,
        note: note,
      );
}

class ExecuteBulkTransferUseCase {
  final TransferRepository _repository;
  const ExecuteBulkTransferUseCase(this._repository);

  Future<void> call({
    required List<BulkTransferRecipient> recipients,
    required double totalAmount,
    required AmountDistributionType distributionType,
    String? pin,
    DateTime? scheduledAt,
  }) =>
      _repository.executeBulkTransfer(
        recipients: recipients,
        totalAmount: totalAmount,
        distributionType: distributionType,
        pin: pin,
        scheduledAt: scheduledAt,
      );
}

class GetBulkTransferTemplatesUseCase {
  final TransferRepository _repository;
  const GetBulkTransferTemplatesUseCase(this._repository);

  Future<List<BulkTransferTemplate>> call() =>
      _repository.getBulkTransferTemplates();
}
