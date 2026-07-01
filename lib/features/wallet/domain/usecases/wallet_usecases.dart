// lib/features/wallet/domain/usecases/wallet_usecases.dart

import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

// ── Wallet ───────────────────────────────────────────────────────────────────

class GetWalletUseCase {
  final WalletRepository _repository;
  const GetWalletUseCase(this._repository);
  Future<WalletEntity> call() => _repository.getWallet();
}

class GetAccountDetailsUseCase {
  final WalletRepository _repository;
  const GetAccountDetailsUseCase(this._repository);
  Future<VirtualAccountEntity> call() => _repository.getAccountDetails();
}

class GenerateQrCodeUseCase {
  final WalletRepository _repository;
  const GenerateQrCodeUseCase(this._repository);
  Future<String> call() => _repository.generateQrCode();
}

// ── Funding / Add Money ──────────────────────────────────────────────────────

class GetAddMoneyOptionsUseCase {
  final WalletRepository _repository;
  const GetAddMoneyOptionsUseCase(this._repository);
  Future<List<AddMoneyOption>> call() => _repository.getAddMoneyOptions();
}

class GetBanksUseCase {
  final WalletRepository _repository;
  const GetBanksUseCase(this._repository);
  Future<List<Bank>> call() => _repository.getBanks();
}

class GenerateUssdCodeUseCase {
  final WalletRepository _repository;
  const GenerateUssdCodeUseCase(this._repository);
  Future<UssdTransferData> call({
    required String bankCode,
    required double amount,
  }) =>
      _repository.generateUssdCode(bankCode: bankCode, amount: amount);
}

class InitiateCardTopUpUseCase {
  final WalletRepository _repository;
  const InitiateCardTopUpUseCase(this._repository);
  Future<CardTopUpResponse> call(CardTopUpRequest request) =>
      _repository.initiateCardTopUp(request);
}

class VerifyCardTopUpOtpUseCase {
  final WalletRepository _repository;
  const VerifyCardTopUpOtpUseCase(this._repository);
  Future<TransactionReceipt> call({
    required String otpReference,
    required String otp,
  }) =>
      _repository.verifyCardTopUpOtp(otpReference: otpReference, otp: otp);
}
