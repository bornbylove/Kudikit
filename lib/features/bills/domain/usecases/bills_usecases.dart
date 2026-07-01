// lib/features/bills/domain/usecases/bills_usecases.dart
//
// FIX SUMMARY:
//   🟠 #3 — GetDataPlansUseCase and DetectNetworkUseCase now use String
//           instead of NetworkProvider, matching the updated BillsRepository
//           interface. No model-layer types in the domain layer.
//
//   🟡 #5 — GetBeneficiariesUseCase now returns List<BillsBeneficiaryEntity>.
//
//   🔴 #2 — ValidateIucUseCase, PayCableTvUseCase, ValidateMeterUseCase, and
//           PayElectricityUseCase are REMOVED. The corresponding repository
//           methods have been removed from the interface because CableTvNotifier
//           and ElectricityNotifier own those flows directly. Re-add when/if
//           those features are migrated through the repository.

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/features/bills/domain/usecases/repositories/bills_repository.dart';

class BuyAirtimeUseCase {
  final BillsRepository _repository;
  const BuyAirtimeUseCase(this._repository);
  Future<BillPaymentResultEntity> call(AirtimePurchaseEntity request) =>
      _repository.buyAirtime(request);
}

class GetDataPlansUseCase {
  final BillsRepository _repository;
  const GetDataPlansUseCase(this._repository);

  /// [network] is the network name string (e.g. "mtn").
  Future<List<DataPlanEntity>> call(String network) =>
      _repository.getDataPlans(network);
}

class BuyDataUseCase {
  final BillsRepository _repository;
  const BuyDataUseCase(this._repository);
  Future<BillPaymentResultEntity> call(DataPurchaseEntity request) =>
      _repository.buyData(request);
}

class GetBeneficiariesUseCase {
  final BillsRepository _repository;
  const GetBeneficiariesUseCase(this._repository);
  Future<List<BillsBeneficiaryEntity>> call() => _repository.getBeneficiaries();
}

class DetectNetworkUseCase {
  final BillsRepository _repository;
  const DetectNetworkUseCase(this._repository);

  /// Returns the detected network name string (e.g. "mtn"), or null.
  String? call(String phoneNumber) => _repository.detectNetwork(phoneNumber);
}
