// lib/provider/provider.dart
//
// Aggregator barrel — re-exports Riverpod providers from their canonical
// feature locations so `import 'package:kudipay/provider/provider.dart';`
// still exposes the full provider surface.

export 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
export 'package:kudipay/features/transaction/presentation/controllers/transaction_provider.dart';
export 'package:kudipay/features/kyc/presentation/controllers/kyc_controllers.dart';
export 'package:kudipay/features/linkdevice/presentation/controllers/device_linking_provider.dart';
export 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
export 'package:kudipay/features/notification/presentation/controllers/notification_provider.dart';
export 'package:kudipay/features/email/presentation/controllers/email_provider.dart';
export 'package:kudipay/features/wallet/presentation/controllers/wallet_provider.dart';
export 'package:kudipay/features/tier/presentation/controllers/tier_provider.dart';
export 'package:kudipay/features/request/presentation/controllers/request_provider.dart';
export 'package:kudipay/features/bills/presentation/controllers/bills_controllers.dart';
export 'package:kudipay/features/onboarding/presentation/controllers/onboarding_provider.dart';
export 'package:kudipay/features/transactionpin/presentation/controllers/transaction_pin_provider.dart';

// Cross-cutting infrastructure providers (still under lib/provider/).
export 'package:kudipay/provider/connectivity/connectivity_provider.dart';
export 'package:kudipay/provider/funding/funding_provider.dart';
