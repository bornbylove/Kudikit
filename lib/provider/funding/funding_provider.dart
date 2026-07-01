// lib/provider/funding/funding_provider.dart
//
// BACKWARD-COMPAT RE-EXPORT ONLY.
// All Wallet + Funding state now lives in:
//   lib/features/wallet/presentation/controllers/wallet_controllers.dart
//
// This file exists so that any remaining legacy imports of
//   'package:kudipay/provider/funding/funding_provider.dart'
// continue to compile without changes during the phased migration.
//
// DO NOT add new providers here. Use wallet_controllers.dart directly.

export 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart'
    show
        // Add Money Options
        AddMoneyOptionsState,
        AddMoneyOptionsNotifier,
        addMoneyOptionsProvider,
        selectedAddMoneyOptionProvider,
        // Account Details
        AccountDetailsState,
        AccountDetailsNotifier,
        accountDetailsProvider,
        // QR Code
        QrCodeState,
        QrCodeNotifier,
        qrCodeProvider,
        // Banks
        BanksState,
        BanksNotifier,
        banksProvider,
        selectedBankProvider,
        bankSearchQueryProvider,
        // USSD
        UssdTransferState,
        UssdTransferNotifier,
        ussdTransferProvider,
        // Card Top-Up
        CardTopUpStep,
        CardTopUpState,
        CardTopUpNotifier,
        cardTopUpProvider,
        // Misc
        selectedAmountProvider;

// AddMoneyError and AddMoneyErrorType were previously defined here.
// They are now simplified — the controllers use plain String? errors.
// Any UI that referenced AddMoneyError.message now reads the String? directly.
// Keep these stubs so existing switch statements referencing AddMoneyErrorType
// compile until presentation files are migrated.

enum AddMoneyErrorType {
  network,
  authentication,
  serverError,
  validation,
  timeout,
  unknown,
}

class AddMoneyError {
  final String message;
  final AddMoneyErrorType type;
  final int? statusCode;
  final bool isRetryable;

  const AddMoneyError({
    required this.message,
    required this.type,
    this.statusCode,
    this.isRetryable = true,
  });

  @override
  String toString() => message;
}
