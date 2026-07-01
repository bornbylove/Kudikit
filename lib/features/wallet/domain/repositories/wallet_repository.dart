// lib/features/wallet/domain/repositories/wallet_repository.dart

import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

abstract interface class WalletRepository {
  // ── Wallet ──────────────────────────────────────────────────────────────
  /// Fetches balance and account details in parallel.
  Future<WalletEntity> getWallet();

  /// Fetches virtual account details for bank transfer.
  Future<VirtualAccountEntity> getAccountDetails();

  /// Generates a QR code URL for cash deposit / receive payment.
  Future<String> generateQrCode();

  // ── Funding / Add Money ─────────────────────────────────────────────────
  /// Returns the list of funding method options.
  Future<List<AddMoneyOption>> getAddMoneyOptions();

  /// Returns the list of supported banks.
  Future<List<Bank>> getBanks();

  /// Generates a USSD code for the given bank and amount.
  Future<UssdTransferData> generateUssdCode({
    required String bankCode,
    required double amount,
  });

  /// Initiates a card top-up with full card details.
  Future<CardTopUpResponse> initiateCardTopUp(CardTopUpRequest request);

  /// Verifies the OTP from a card top-up and returns the receipt.
  Future<TransactionReceipt> verifyCardTopUpOtp({
    required String otpReference,
    required String otp,
  });
}
