// lib/provider/wallet/wallet_provider.dart
//
// BACKWARD-COMPAT RE-EXPORT ONLY.
// All wallet state now lives in:
//   lib/features/wallet/presentation/controllers/wallet_controllers.dart
//
// This file exists so imports of 'package:kudipay/provider/wallet/wallet_provider.dart'
// continue to compile without changes during the phased migration.
//
// DO NOT add new providers here. Use wallet_controllers.dart directly.

export 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart'
    show WalletState, WalletNotifier, walletProvider;
