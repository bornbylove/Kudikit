// lib/features/wallet/data/repositories/wallet_repository_impl.dart

import 'package:kudipay/features/wallet/data/datasources/wallet_remote_datasources.dart';
import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _dataSource;
  const WalletRepositoryImpl(this._dataSource);

  @override
  Future<WalletEntity> getWallet() => _dataSource.getWallet();

  @override
  Future<VirtualAccountEntity> getAccountDetails() =>
      _dataSource.getAccountDetails();

  @override
  Future<String> generateQrCode() => _dataSource.generateQrCode();

  @override
  Future<List<AddMoneyOption>> getAddMoneyOptions() =>
      _dataSource.getAddMoneyOptions();

  @override
  Future<List<Bank>> getBanks() => _dataSource.getBanks();

  @override
  Future<UssdTransferData> generateUssdCode({
    required String bankCode,
    required double amount,
  }) =>
      _dataSource.generateUssdCode(bankCode: bankCode, amount: amount);

  @override
  Future<CardTopUpResponse> initiateCardTopUp(CardTopUpRequest request) =>
      _dataSource.initiateCardTopUp(request);

  @override
  Future<TransactionReceipt> verifyCardTopUpOtp({
    required String otpReference,
    required String otp,
  }) =>
      _dataSource.verifyCardTopUpOtp(otpReference: otpReference, otp: otp);
}
