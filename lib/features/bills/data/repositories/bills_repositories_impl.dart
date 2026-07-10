// lib/features/bills/data/repositories/bills_repository_impl.dart
//
// FIX SUMMARY (vs previous version):
//   • Cable TV and Electricity methods no longer throw UnimplementedError.
//     They are removed from this impl because those features bypass the
//     repository layer entirely (CableTvNotifier / ElectricityNotifier talk
//     directly to DioClient). The BillsRepository interface has been narrowed
//     to only the methods this impl can actually fulfil — see bills_repository.dart.
//   • NetworkProvider is no longer exposed in the domain repository interface.
//     getDataPlans() and detectNetwork() now use String at the interface
//     boundary; the NetworkProvider enum lookup happens here in the impl.
//   • BillsBeneficiary (model type) replaced with BillsBeneficiaryEntity
//     (domain type) at the interface boundary; mapping done here in the impl.
//   • buyData() no longer maps NetworkProvider twice for the same value.

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/features/bills/domain/usecases/repositories/bills_repository.dart';

import 'package:kudipay/features/bills/domain/entities/bill_model.dart';
import 'package:kudipay/services/bill_service.dart';

class BillsRepositoryImpl implements BillsRepository {
  final BillsService _service;
  const BillsRepositoryImpl(this._service);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a network name string to a [NetworkProvider] enum value.
  /// Throws a [ArgumentError] with a clear message when the string is
  /// unrecognised — instead of silently defaulting to MTN, which could
  /// cause charges on the wrong network.
  NetworkProvider _resolveNetwork(String networkName) {
    return NetworkProvider.values.firstWhere(
      (n) => n.name.toLowerCase() == networkName.toLowerCase(),
      orElse: () => throw ArgumentError(
        'Unknown network "$networkName". '
        'Valid values: ${NetworkProvider.values.map((n) => n.name).join(', ')}',
      ),
    );
  }

  // ── Airtime ───────────────────────────────────────────────────────────────

  @override
  Future<BillPaymentResultEntity> buyAirtime(AirtimePurchaseEntity req) async {
    final response = await _service.buyAirtime(
      AirtimePurchaseRequest(
        phoneNumber: req.phoneNumber,
        network: _resolveNetwork(req.network),
        amount: req.amount,
      ),
    );
    return BillPaymentResultEntity(
      transactionId: response.transactionId,
      amount: response.amount,
      phoneNumber: response.phoneNumber,
      providerName: response.network,
      transactionDate: response.createdAt,
      isSuccessful: response.success,
    );
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  @override
  Future<List<DataPlanEntity>> getDataPlans(String networkName) async {
    final network = _resolveNetwork(networkName);
    final plans = await _service.getDataPlans(network);
    return plans
        .map((p) => DataPlanEntity(
              id: p.id,
              name: p.name,
              price: p.price,
              validity: p.validity.name,
              network: p.network.name,
            ))
        .toList();
  }

  @override
  Future<BillPaymentResultEntity> buyData(DataPurchaseEntity req) async {
    // FIX: resolve the network once and reuse — avoids double lookup and the
    // risk of the two lookups disagreeing if the string changes between calls.
    final network = _resolveNetwork(req.plan.network);

    final response = await _service.buyData(
      DataPurchaseRequest(
        phoneNumber: req.phoneNumber,
        network: network,
        plan: DataPlan(
          id: req.plan.id,
          name: req.plan.name,
          price: req.plan.price,
          validity: DataValidity.values.firstWhere(
            (v) => v.name == req.plan.validity,
            orElse: () => DataValidity.monthly,
          ),
          validityLabel: req.plan.validity,
          description: '${req.plan.name} • ${req.plan.validity}',
          network: network,
        ),
      ),
    );
    return BillPaymentResultEntity(
      transactionId: response.transactionId,
      amount: response.plan.price,
      phoneNumber: response.phoneNumber,
      providerName: response.network,
      transactionDate: response.createdAt,
      isSuccessful: response.success,
    );
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  @override
  Future<List<BillsBeneficiaryEntity>> getBeneficiaries() async {
    final raw = await _service.getBeneficiaries();
    return raw
        .map((b) => BillsBeneficiaryEntity(
              id: b.id,
              name: b.name,
              phoneNumber: b.phoneNumber,
              network: b.network.name,
              lastPurchaseType: b.lastPurchaseType.name,
              lastPurchaseDate: b.lastPurchaseDate,
            ))
        .toList();
  }

  @override
  String? detectNetwork(String phoneNumber) {
    final provider = _service.detectNetwork(phoneNumber);
    return provider?.name; // return the name string, not the enum
  }
}
