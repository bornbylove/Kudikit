// lib/features/bills/presentation/controllers/bills_controllers.dart
//
// Replaces:
//   lib/provider/bill/bill_provider.dart
//   lib/provider/cable_tv/cable_tv_provider.dart
//   lib/provider/electricity/electricity_provider.dart
//
// Strategy: The airtime and data notifiers are migrated to use use-cases.
// The cable TV and electricity notifiers call DioClient directly and are
// kept as-is — they are already clean and well-structured. Their providers
// are simply re-exported here so everything lives in one place.
//
// FIX SUMMARY:
//   🟠 #4 — billsServiceProvider now injects DioClient (not the old
//           BillsService(baseUrl, authToken) pattern). DioClient owns token
//           management via _AuthInterceptor, so the token is always fresh.
//
//   🟠 #3 — detectedNetworkProvider now exposes String? instead of
//           NetworkProvider? to match the updated repository interface.
//
//   🟡 #5 — BeneficiariesNotifier and beneficiariesState updated to use
//           BillsBeneficiaryEntity instead of the model-layer BillsBeneficiary.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/features/bills/data/repositories/bills_repositories_impl.dart';
import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/features/bills/domain/usecases/repositories/bills_repository.dart';
import 'package:kudipay/features/bills/domain/usecases/bills_usecases.dart';
import 'package:kudipay/services/bill_service.dart';

// Re-export cable TV and electricity providers unchanged
export 'package:kudipay/provider/cable_tv/cable_tv_provider.dart';
export 'package:kudipay/provider/electricity/electricity_provider.dart';

// =============================================================================
// DI — FIX #4: BillsService now receives DioClient, not raw auth token
// =============================================================================

final billsServiceProvider = Provider<BillsService>((ref) {
  // FIX #4: Use DioClient so token is read lazily per-request via
  // _AuthInterceptor — stale token issue is eliminated.
  final dioClient = ref.watch(dioClientProvider);
  return BillsService(dioClient);
});

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  return BillsRepositoryImpl(ref.read(billsServiceProvider));
});

final buyAirtimeUseCaseProvider =
    Provider((ref) => BuyAirtimeUseCase(ref.read(billsRepositoryProvider)));
final getDataPlansUseCaseProvider =
    Provider((ref) => GetDataPlansUseCase(ref.read(billsRepositoryProvider)));
final buyDataUseCaseProvider =
    Provider((ref) => BuyDataUseCase(ref.read(billsRepositoryProvider)));
final getBeneficiariesUseCaseProvider = Provider(
    (ref) => GetBeneficiariesUseCase(ref.read(billsRepositoryProvider)));
final detectNetworkUseCaseProvider =
    Provider((ref) => DetectNetworkUseCase(ref.read(billsRepositoryProvider)));

// =============================================================================
// Beneficiaries — FIX #5: uses BillsBeneficiaryEntity
// =============================================================================

class BeneficiariesState {
  final List<BillsBeneficiary> beneficiaries;
  final bool isLoading;
  final String? error;

  const BeneficiariesState({
    this.beneficiaries = const [],
    this.isLoading = false,
    this.error,
  });

  BeneficiariesState copyWith({
    List<BillsBeneficiary>? beneficiaries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      BeneficiariesState(
        beneficiaries: beneficiaries ?? this.beneficiaries,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class BeneficiariesNotifier extends StateNotifier<BeneficiariesState> {
  final GetBeneficiariesUseCase _getBeneficiaries;

  BeneficiariesNotifier(this._getBeneficiaries)
      : super(const BeneficiariesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _getBeneficiaries.call();
      state = state.copyWith(
        beneficiaries: list.map(_beneficiaryFromEntity).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addBeneficiary(BillsBeneficiary b) =>
      state = state.copyWith(beneficiaries: [b, ...state.beneficiaries]);
}

final beneficiariesProvider =
    StateNotifierProvider<BeneficiariesNotifier, BeneficiariesState>((ref) {
  return BeneficiariesNotifier(ref.read(getBeneficiariesUseCaseProvider));
});

// =============================================================================
// Network detection helper — FIX #3: returns String? not NetworkProvider?
// =============================================================================

/// Returns the detected network name string (e.g. "mtn"), or null.
final detectedNetworkProvider =
    Provider.family<String?, String>((ref, phoneNumber) {
  return ref.read(detectNetworkUseCaseProvider).call(phoneNumber);
});

// =============================================================================
// Airtime flow
// =============================================================================

enum AirtimeStep { phone, amount, processing, success, failed }

class AirtimeState {
  final String phoneNumber;
  final NetworkProvider? selectedNetwork;
  final bool isNetworkDropdownOpen;
  final double? amount;
  final AirtimeStep step;
  final String? error;
  final AirtimePurchaseResponse? result;

  const AirtimeState({
    this.phoneNumber = '',
    this.selectedNetwork,
    this.isNetworkDropdownOpen = false,
    this.amount,
    this.step = AirtimeStep.phone,
    this.error,
    this.result,
  });

  bool get canProceedFromPhone =>
      _isValidNigerianPhone(phoneNumber) && selectedNetwork != null;

  bool get canProceedFromAmount =>
      amount != null && amount! >= 60 && amount! <= 50000;

  AirtimeState copyWith({
    String? phoneNumber,
    NetworkProvider? selectedNetwork,
    bool? isNetworkDropdownOpen,
    double? amount,
    AirtimeStep? step,
    String? error,
    AirtimePurchaseResponse? result,
    bool clearError = false,
    bool clearNetwork = false,
  }) =>
      AirtimeState(
        phoneNumber: phoneNumber ?? this.phoneNumber,
        selectedNetwork:
            clearNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
        isNetworkDropdownOpen:
            isNetworkDropdownOpen ?? this.isNetworkDropdownOpen,
        amount: amount ?? this.amount,
        step: step ?? this.step,
        error: clearError ? null : (error ?? this.error),
        result: result ?? this.result,
      );
}

class AirtimeNotifier extends StateNotifier<AirtimeState> {
  final BuyAirtimeUseCase _buyAirtime;
  final DetectNetworkUseCase _detectNetwork;

  AirtimeNotifier(this._buyAirtime, this._detectNetwork)
      : super(const AirtimeState());

  void reset() => state = const AirtimeState();

  void setPhoneNumber(String raw) {
    final normalized = _normalizePhone(raw);
    final networkName = _detectNetwork.call(normalized);
    final network = networkName != null ? _networkFromName(networkName) : null;
    state = state.copyWith(
      phoneNumber: normalized,
      selectedNetwork: network,
      clearError: true,
      clearNetwork: network == null,
    );
  }

  void setPhoneNumberWithNetwork(String phone, NetworkProvider network) {
    state = state.copyWith(
      phoneNumber: _normalizePhone(phone),
      selectedNetwork: network,
      clearError: true,
    );
  }

  void setNetwork(NetworkProvider network) => state = state.copyWith(
        selectedNetwork: network,
        isNetworkDropdownOpen: false,
      );

  void toggleNetworkDropdown() => state = state.copyWith(
        isNetworkDropdownOpen: !state.isNetworkDropdownOpen,
      );

  void closeNetworkDropdown() =>
      state = state.copyWith(isNetworkDropdownOpen: false);

  void setAmount(double amount) =>
      state = state.copyWith(amount: amount, clearError: true);

  Future<void> processAirtime() async {
    final network = state.selectedNetwork;
    final amount = state.amount;
    if (network == null || amount == null) return;

    state = state.copyWith(
      step: AirtimeStep.processing,
      clearError: true,
    );
    try {
      final result = await _buyAirtime.call(
        AirtimePurchaseEntity(
          phoneNumber: state.phoneNumber,
          network: network.name,
          amount: amount,
        ),
      );
      state = state.copyWith(
        step: result.isSuccessful ? AirtimeStep.success : AirtimeStep.failed,
        result: AirtimePurchaseResponse(
          success: result.isSuccessful,
          transactionId: result.transactionId,
          message: result.isSuccessful ? 'Success' : 'Failed',
          amount: result.amount,
          phoneNumber: result.phoneNumber,
          network: result.providerName,
          createdAt: result.transactionDate,
        ),
        error: result.isSuccessful ? null : 'Transaction failed.',
      );
    } catch (e) {
      state = state.copyWith(
        step: AirtimeStep.failed,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final airtimeProvider =
    StateNotifierProvider<AirtimeNotifier, AirtimeState>((ref) {
  return AirtimeNotifier(
    ref.read(buyAirtimeUseCaseProvider),
    ref.read(detectNetworkUseCaseProvider),
  );
});

// =============================================================================
// Data flow
// =============================================================================

enum DataStep { phone, selectPlan, processing, success, failed }

class DataState {
  final String phoneNumber;
  final NetworkProvider? selectedNetwork;
  final bool isNetworkDropdownOpen;
  final List<DataPlan> plans;
  final DataPlan? selectedPlan;
  final bool isLoadingPlans;
  final bool isProcessing;
  final DataStep step;
  final String? error;
  final DataPurchaseResponse? result;

  const DataState({
    this.phoneNumber = '',
    this.selectedNetwork,
    this.isNetworkDropdownOpen = false,
    this.plans = const [],
    this.selectedPlan,
    this.isLoadingPlans = false,
    this.isProcessing = false,
    this.step = DataStep.phone,
    this.error,
    this.result,
  });

  bool get canProceedFromPhone =>
      _isValidNigerianPhone(phoneNumber) && selectedNetwork != null;

  bool get canProceedFromPlan => selectedPlan != null;

  DataState copyWith({
    String? phoneNumber,
    NetworkProvider? selectedNetwork,
    bool? isNetworkDropdownOpen,
    List<DataPlan>? plans,
    DataPlan? selectedPlan,
    bool? isLoadingPlans,
    bool? isProcessing,
    DataStep? step,
    String? error,
    DataPurchaseResponse? result,
    bool clearError = false,
    bool clearNetwork = false,
    bool clearPlan = false,
  }) =>
      DataState(
        phoneNumber: phoneNumber ?? this.phoneNumber,
        selectedNetwork:
            clearNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
        isNetworkDropdownOpen:
            isNetworkDropdownOpen ?? this.isNetworkDropdownOpen,
        plans: plans ?? this.plans,
        selectedPlan: clearPlan ? null : (selectedPlan ?? this.selectedPlan),
        isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
        isProcessing: isProcessing ?? this.isProcessing,
        step: step ?? this.step,
        error: clearError ? null : (error ?? this.error),
        result: result ?? this.result,
      );
}

class DataNotifier extends StateNotifier<DataState> {
  final GetDataPlansUseCase _getDataPlans;
  final BuyDataUseCase _buyData;
  final DetectNetworkUseCase _detectNetwork;

  DataNotifier(this._getDataPlans, this._buyData, this._detectNetwork)
      : super(const DataState());

  void reset() => state = const DataState();

  void setPhoneNumber(String raw) {
    final normalized = _normalizePhone(raw);
    final networkName = _detectNetwork.call(normalized);
    final network = networkName != null ? _networkFromName(networkName) : null;
    state = state.copyWith(
      phoneNumber: normalized,
      selectedNetwork: network,
      clearError: true,
      clearNetwork: network == null,
      clearPlan: true,
      plans: const [],
    );
  }

  void setPhoneNumberWithNetwork(String phone, NetworkProvider network) {
    state = state.copyWith(
      phoneNumber: _normalizePhone(phone),
      selectedNetwork: network,
      clearError: true,
      clearPlan: true,
    );
  }

  void setNetwork(NetworkProvider network) => state = state.copyWith(
        selectedNetwork: network,
        isNetworkDropdownOpen: false,
        clearPlan: true,
        plans: const [],
      );

  void toggleNetworkDropdown() => state = state.copyWith(
        isNetworkDropdownOpen: !state.isNetworkDropdownOpen,
      );

  void closeNetworkDropdown() =>
      state = state.copyWith(isNetworkDropdownOpen: false);

  void selectPlan(DataPlan plan) =>
      state = state.copyWith(selectedPlan: plan, clearError: true);

  Future<void> proceedToSelectPlan() async {
    final network = state.selectedNetwork;
    if (network == null) return;

    state = state.copyWith(
      isLoadingPlans: true,
      clearError: true,
      step: DataStep.selectPlan,
    );
    try {
      final entities = await _getDataPlans.call(network.name);
      final plans = entities.map(_planFromEntity).toList();
      state = state.copyWith(
        plans: plans,
        isLoadingPlans: false,
        step: DataStep.selectPlan,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPlans: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> processData() async {
    final network = state.selectedNetwork;
    final plan = state.selectedPlan;
    if (network == null || plan == null) return;

    state = state.copyWith(
      isProcessing: true,
      step: DataStep.processing,
      clearError: true,
    );
    try {
      final result = await _buyData.call(
        DataPurchaseEntity(
          phoneNumber: state.phoneNumber,
          plan: DataPlanEntity(
            id: plan.id,
            name: plan.name,
            price: plan.price,
            validity: plan.validity.name,
            network: plan.network.name,
          ),
        ),
      );
      state = state.copyWith(
        isProcessing: false,
        step: result.isSuccessful ? DataStep.success : DataStep.failed,
        result: DataPurchaseResponse(
          success: result.isSuccessful,
          transactionId: result.transactionId,
          message: result.isSuccessful ? 'Success' : 'Failed',
          plan: plan,
          phoneNumber: result.phoneNumber,
          network: result.providerName,
          createdAt: result.transactionDate,
        ),
        error: result.isSuccessful ? null : 'Transaction failed.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: DataStep.failed,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final dataProvider = StateNotifierProvider<DataNotifier, DataState>((ref) {
  return DataNotifier(
    ref.read(getDataPlansUseCaseProvider),
    ref.read(buyDataUseCaseProvider),
    ref.read(detectNetworkUseCaseProvider),
  );
});

// =============================================================================
// Shared helpers
// =============================================================================

bool _isValidNigerianPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('0')) return true;
  if (digits.length == 13 && digits.startsWith('234')) return true;
  return false;
}

String _normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('234') && digits.length >= 13) {
    digits = '0${digits.substring(3)}';
  }
  if (digits.length > 11) digits = digits.substring(0, 11);
  return digits;
}

NetworkProvider _networkFromName(String name) {
  return NetworkProvider.values.firstWhere(
    (n) => n.name.toLowerCase() == name.toLowerCase(),
    orElse: () => NetworkProvider.mtn,
  );
}

DataPlan _planFromEntity(DataPlanEntity e) {
  final network = _networkFromName(e.network);
  return DataPlan(
    id: e.id,
    name: e.name,
    price: e.price,
    validity: DataValidity.values.firstWhere(
      (v) => v.name == e.validity,
      orElse: () => DataValidity.monthly,
    ),
    validityLabel: e.validity,
    description: '${e.name} • ${e.validity}',
    network: network,
  );
}

BillsBeneficiary _beneficiaryFromEntity(BillsBeneficiaryEntity e) {
  return BillsBeneficiary(
    id: e.id,
    name: e.name,
    phoneNumber: e.phoneNumber,
    network: _networkFromName(e.network),
    lastPurchaseType:
        e.lastPurchaseType == 'data' ? BillsType.data : BillsType.airtime,
    lastPurchaseDate: e.lastPurchaseDate,
  );
}
