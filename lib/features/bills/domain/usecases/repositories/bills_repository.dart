// lib/features/bills/domain/repositories/bills_repository.dart
//
// FIX SUMMARY (vs previous version):
//   • Cable TV and Electricity methods removed. Those features bypass this
//     repository and talk to DioClient directly via their own notifiers.
//     Keeping stub methods that throw UnimplementedError in the interface
//     creates a false contract that will crash any caller at runtime.
//     If Cable TV / Electricity are ever routed through the repository,
//     add the methods back at that point.
//   • NetworkProvider (model enum) replaced with String at the interface
//     boundary. The domain layer must not know about model-layer types.
//   • getBeneficiaries() now returns List<BillsBeneficiaryEntity> instead
//     of List<BillsBeneficiary> for the same reason.
//   • detectNetwork() return type changed from NetworkProvider? to String?

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';

abstract interface class BillsRepository {
  // ── Airtime ───────────────────────────────────────────────────────────────
  Future<BillPaymentResultEntity> buyAirtime(AirtimePurchaseEntity request);

  // ── Data ──────────────────────────────────────────────────────────────────

  /// [networkName] is a plain string matching a NetworkProvider.name value,
  /// e.g. "mtn", "airtel", "glo", "nineMobile".
  Future<List<DataPlanEntity>> getDataPlans(String networkName);
  Future<BillPaymentResultEntity> buyData(DataPurchaseEntity request);

  // ── Shared ────────────────────────────────────────────────────────────────
  Future<List<BillsBeneficiaryEntity>> getBeneficiaries();

  /// Returns the detected network name string, or null if unrecognised.
  String? detectNetwork(String phoneNumber);
}
