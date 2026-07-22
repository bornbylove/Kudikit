// lib/features/transfer/presentation/controllers/transfer_controllers.dart
//
// Replaces:
//   lib/provider/P2P_transfer/p2p_transfer_provider.dart
//   lib/provider/transfer/bulk_transfer_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/core/network/dio_provider.dart';
import 'package:kudipay/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:kudipay/features/transfer/domain/usecases/transfer_usecases.dart';
import 'package:kudipay/features/transfer/domain/entities/bulk_transfer_model.dart';

// =============================================================================
// DI
// =============================================================================

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepositoryImpl(ref.read(dioClientProvider));
});

final validateAccountUseCaseProvider = Provider(
    (ref) => ValidateAccountUseCase(ref.read(transferRepositoryProvider)));
final getRecentContactsUseCaseProvider = Provider(
    (ref) => GetRecentContactsUseCase(ref.read(transferRepositoryProvider)));
final processTransferUseCaseProvider = Provider(
    (ref) => ProcessTransferUseCase(ref.read(transferRepositoryProvider)));
final executeBulkTransferUseCaseProvider = Provider(
    (ref) => ExecuteBulkTransferUseCase(ref.read(transferRepositoryProvider)));
final getBulkTransferTemplatesUseCaseProvider = Provider((ref) =>
    GetBulkTransferTemplatesUseCase(ref.read(transferRepositoryProvider)));

// =============================================================================
// P2P Transfer — State
// =============================================================================

class TransferData {
  final RecipientEntity? recipient;
  final double? amount;
  final TransactionCategory? category;
  final String? note;
  final double? balance;
  final double? fee;

  const TransferData({
    this.recipient,
    this.amount,
    this.category,
    this.note,
    this.balance,
    this.fee,
  });

  bool get hasInsufficientBalance {
    if (amount == null || balance == null || fee == null) return false;
    return (amount! + fee!) > balance!;
  }

  TransferData copyWith({
    RecipientEntity? recipient,
    double? amount,
    TransactionCategory? category,
    String? note,
    double? balance,
    double? fee,
  }) =>
      TransferData(
        recipient: recipient ?? this.recipient,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        balance: balance ?? this.balance,
        fee: fee ?? this.fee,
      );
}

class P2PTransferState {
  final TransferType transferType;
  final TransferData transferData;
  final List<RecentContactEntity> recentContacts;
  final List<RecentContactEntity> favouriteContacts;
  final bool isValidatingAccount;
  final bool isProcessingTransfer;
  final String? error;
  final TransferResultEntity? transactionResult;
  final bool showPinDialog;
  final bool showConfirmDialog;

  const P2PTransferState({
    this.transferType = TransferType.kudikit,
    this.transferData = const TransferData(),
    this.recentContacts = const [],
    this.favouriteContacts = const [],
    this.isValidatingAccount = false,
    this.isProcessingTransfer = false,
    this.error,
    this.transactionResult,
    this.showPinDialog = false,
    this.showConfirmDialog = false,
  });

  P2PTransferState copyWith({
    TransferType? transferType,
    TransferData? transferData,
    List<RecentContactEntity>? recentContacts,
    List<RecentContactEntity>? favouriteContacts,
    bool? isValidatingAccount,
    bool? isProcessingTransfer,
    String? error,
    TransferResultEntity? transactionResult,
    bool? showPinDialog,
    bool? showConfirmDialog,
    bool clearError = false,
  }) =>
      P2PTransferState(
        transferType: transferType ?? this.transferType,
        transferData: transferData ?? this.transferData,
        recentContacts: recentContacts ?? this.recentContacts,
        favouriteContacts: favouriteContacts ?? this.favouriteContacts,
        isValidatingAccount: isValidatingAccount ?? this.isValidatingAccount,
        isProcessingTransfer: isProcessingTransfer ?? this.isProcessingTransfer,
        error: clearError ? null : (error ?? this.error),
        transactionResult: transactionResult ?? this.transactionResult,
        showPinDialog: showPinDialog ?? this.showPinDialog,
        showConfirmDialog: showConfirmDialog ?? this.showConfirmDialog,
      );
}

// =============================================================================
// P2P Transfer — Notifier
// =============================================================================

class P2PTransferNotifier extends StateNotifier<P2PTransferState> {
  final ValidateAccountUseCase _validateAccount;
  final GetRecentContactsUseCase _getRecentContacts;
  final ProcessTransferUseCase _processTransfer;

  P2PTransferNotifier({
    required ValidateAccountUseCase validateAccount,
    required GetRecentContactsUseCase getRecentContacts,
    required ProcessTransferUseCase processTransfer,
  })  : _validateAccount = validateAccount,
        _getRecentContacts = getRecentContacts,
        _processTransfer = processTransfer,
        super(const P2PTransferState()) {
    _loadRecentContacts();
  }

  Future<void> _loadRecentContacts() async {
    try {
      final contacts = await _getRecentContacts.call();
      state = state.copyWith(recentContacts: contacts);
    } catch (_) {
      // Silently fail — not critical
    }
  }

  void setTransferType(TransferType type) => state = state.copyWith(
        transferType: type,
        transferData: const TransferData(),
      );

  Future<void> validateAccount(String accountNumber) async {
    state = state.copyWith(isValidatingAccount: true, clearError: true);
    try {
      final recipient = await _validateAccount.call(
        accountNumber: accountNumber,
        type: state.transferType,
      );
      state = state.copyWith(
        isValidatingAccount: false,
        transferData: state.transferData.copyWith(recipient: recipient),
      );
    } on SocketException {
      state = state.copyWith(
        isValidatingAccount: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isValidatingAccount: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectRecipient(RecipientEntity recipient) => state = state.copyWith(
      transferData: state.transferData.copyWith(recipient: recipient));

  void setAmount(double amount) => state =
      state.copyWith(transferData: state.transferData.copyWith(amount: amount));

  void setCategory(TransactionCategory category) => state = state.copyWith(
      transferData: state.transferData.copyWith(category: category));

  void setNote(String note) => state =
      state.copyWith(transferData: state.transferData.copyWith(note: note));

  void showConfirmation() => state = state.copyWith(showConfirmDialog: true);
  void hideConfirmation() => state = state.copyWith(showConfirmDialog: false);
  void showPinEntry() =>
      state = state.copyWith(showPinDialog: true, showConfirmDialog: false);
  void hidePinEntry() => state = state.copyWith(showPinDialog: false);

  Future<void> processTransfer(String pin) async {
    if (pin.length != 4) {
      state = state.copyWith(error: 'Invalid PIN');
      return;
    }
    state = state.copyWith(isProcessingTransfer: true, clearError: true);
    try {
      final result = await _processTransfer.call(
        recipient: state.transferData.recipient!,
        amount: state.transferData.amount!,
        pin: pin,
        category: state.transferData.category,
        note: state.transferData.note,
      );
      state = state.copyWith(
        isProcessingTransfer: false,
        transactionResult: result,
        showPinDialog: false,
      );
    } on SocketException {
      state = state.copyWith(
        isProcessingTransfer: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessingTransfer: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Persists the current recipient as a favourite when backend support exists.
  void addFavourite() {
    // No-op until favourites API is wired; UI checkbox is preserved.
  }

  void reset() {
    state = const P2PTransferState();
    _loadRecentContacts();
  }
}

final p2pTransferProvider =
    StateNotifierProvider<P2PTransferNotifier, P2PTransferState>((ref) {
  return P2PTransferNotifier(
    validateAccount: ref.read(validateAccountUseCaseProvider),
    getRecentContacts: ref.read(getRecentContactsUseCaseProvider),
    processTransfer: ref.read(processTransferUseCaseProvider),
  );
});

final quickAmountsProvider =
    Provider<List<double>>((ref) => [200, 1000, 2000, 3000, 5000, 9999]);

// =============================================================================
// Bulk Transfer — Notifier
// Keeps the same API as the old BulkTransferNotifier
// =============================================================================

class BulkTransferNotifier extends StateNotifier<BulkTransferState> {
  final ExecuteBulkTransferUseCase _executeBulkTransfer;

  BulkTransferNotifier(this._executeBulkTransfer) : super(BulkTransferState());

  void addRecipient(BulkTransferRecipient recipient) =>
      state = state.copyWith(recipients: [...state.recipients, recipient]);

  void removeRecipient(String recipientId) => state = state.copyWith(
      recipients: state.recipients.where((r) => r.id != recipientId).toList());

  void updateRecipient(String recipientId, BulkTransferRecipient updated) =>
      state = state.copyWith(
        recipients: state.recipients
            .map((r) => r.id == recipientId ? updated : r)
            .toList(),
      );

  void setDistributionType(AmountDistributionType type) =>
      state = state.copyWith(distributionType: type);

  void setAmountPerRecipient(double amount) =>
      state = state.copyWith(amountPerRecipient: amount);

  void setTotalAmount(double amount) =>
      state = state.copyWith(totalAmount: amount);

  void setScheduledTransfer({
    required bool isScheduled,
    DateTime? date,
    TimeOfDay? time,
  }) =>
      state = state.copyWith(
        isScheduled: isScheduled,
        scheduledDate: date,
        scheduledTime: time,
      );

  void clearRecipients() => state = state.copyWith(recipients: []);

  void loadFromTemplate(BulkTransferTemplate template) =>
      state = state.copyWith(recipients: template.recipients);

  Future<void> executeBulkTransfer({String? pin}) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Invalid transfer data');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _executeBulkTransfer.call(
        recipients: state.recipients,
        totalAmount: state.totalAmount ?? state.calculatedTotalAmount,
        distributionType: state.distributionType,
        pin: pin,
        scheduledAt: state.isScheduled ? state.scheduledDate : null,
      );
      state = state.copyWith(isLoading: false);
      reset();
    } on KudiApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = BulkTransferState();
}

final bulkTransferProvider =
    StateNotifierProvider<BulkTransferNotifier, BulkTransferState>((ref) {
  return BulkTransferNotifier(ref.read(executeBulkTransferUseCaseProvider));
});

final bulkTransferTemplatesProvider =
    FutureProvider<List<BulkTransferTemplate>>((ref) async {
  return ref.read(getBulkTransferTemplatesUseCaseProvider).call();
});

// Backward-compatible type aliases — remove once all screens are migrated
typedef RecipientInfo = RecipientEntity;
typedef RecentContact = RecentContactEntity;
typedef TransactionResult = TransferResultEntity;
