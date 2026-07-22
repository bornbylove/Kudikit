// lib/features/wallet/data/datasources/wallet_remote_datasource.dart
//
// All raw HTTP calls for the Wallet feature. The repository impl delegates
// every network interaction here so it stays clean and easily testable.

import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

abstract interface class WalletRemoteDataSource {
  Future<WalletEntity> getWallet();
  Future<VirtualAccountEntity> getAccountDetails();
  Future<String> generateQrCode();
  Future<List<AddMoneyOption>> getAddMoneyOptions();
  Future<List<Bank>> getBanks();
  Future<UssdTransferData> generateUssdCode({
    required String bankCode,
    required double amount,
  });
  Future<CardTopUpResponse> initiateCardTopUp(CardTopUpRequest request);
  Future<TransactionReceipt> verifyCardTopUpOtp({
    required String otpReference,
    required String otp,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final DioClient _client;
  const WalletRemoteDataSourceImpl(this._client);

  @override
  Future<WalletEntity> getWallet() async {
    final results = await Future.wait([
      _client.get<Map<String, dynamic>>('/wallet/balance'),
      _client.get<Map<String, dynamic>>('/wallet/account-details'),
    ]);

    final balanceData = results[0].data!;
    final acctData = results[1].data!;

    return WalletEntity(
      balance: (balanceData['balance'] as num).toDouble(),
      accountNumber: acctData['account_number'] as String,
      accountName: acctData['account_name'] as String,
      bankName: (acctData['bank_name'] as String?) ?? 'KudiPay MFB',
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<VirtualAccountEntity> getAccountDetails() async {
    final res =
        await _client.get<Map<String, dynamic>>('/wallet/account-details');
    final data = res.data!;
    return VirtualAccountEntity(
      accountNumber: data['account_number'] as String,
      accountName: data['account_name'] as String,
      bankName: data['bank_name'] as String,
      referenceCode: data['reference_code'] as String?,
    );
  }

  @override
  Future<String> generateQrCode() async {
    final res = await _client.post<Map<String, dynamic>>('/wallet/qr-code');
    return res.data!['qr_code_url'] as String;
  }

  @override
  Future<List<AddMoneyOption>> getAddMoneyOptions() async {
    final res = await _client.get<List<dynamic>>('/add-money/options');
    return (res.data ?? [])
        .map((e) => AddMoneyOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Bank>> getBanks() async {
    final res = await _client.get<List<dynamic>>('/banks');
    return (res.data ?? [])
        .map((e) => Bank.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UssdTransferData> generateUssdCode({
    required String bankCode,
    required double amount,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/add-money/ussd/generate',
      data: {'bank_code': bankCode, 'amount': amount},
    );
    final data = res.data!;
    return UssdTransferData(
      bank: Bank.fromJson(data['bank'] as Map<String, dynamic>),
      amount: (data['amount'] as num).toDouble(),
      ussdCode: data['ussd_code'] as String,
      accountNumber: data['account_number'] as String,
      timeRemaining: Duration(
        minutes: data['time_remaining_minutes'] as int? ?? 4,
      ),
    );
  }

  @override
  Future<CardTopUpResponse> initiateCardTopUp(CardTopUpRequest request) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/add-money/card/initiate',
      data: request.toJson(),
    );
    return CardTopUpResponse.fromJson(res.data!);
  }

  @override
  Future<TransactionReceipt> verifyCardTopUpOtp({
    required String otpReference,
    required String otp,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/add-money/card/verify-otp',
      data: {'otp_reference': otpReference, 'otp': otp},
    );
    return TransactionReceipt.fromJson(res.data!);
  }
}
