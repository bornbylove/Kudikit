// lib/provider/add_money/add_money_provider.dart
//
// Backward-compatibility shim. Canonical add-money providers live in:
//   lib/features/wallet/presentation/controllers/wallet_controllers.dart

export 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart'
    show
        AddMoneyOptionsState,
        AddMoneyOptionsNotifier,
        addMoneyOptionsProvider,
        selectedAddMoneyOptionProvider;
