import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kudipay/features/agent/domain/entities/agent_model.dart';
import 'package:kudipay/features/agent/domain/entities/cashout_transaction_model.dart';
import 'package:kudipay/features/cashout/data/agent_service.dart';
import 'package:kudipay/features/cashout/data/geo_service.dart';
import 'package:kudipay/features/cashout/data/transaction_code_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class CashOutState {
  final Position? userPosition;
  final List<AgentModel> nearbyAgents;
  final AgentModel? selectedAgent;
  final bool isLoadingLocation;
  final bool isLoadingAgents;
  final bool isProcessingTransaction;
  final String? errorMessage;
  final CashOutTransaction? activeTransaction;
  final String searchQuery;

  const CashOutState({
    this.userPosition,
    this.nearbyAgents = const [],
    this.selectedAgent,
    this.isLoadingLocation = false,
    this.isLoadingAgents = false,
    this.isProcessingTransaction = false,
    this.errorMessage,
    this.activeTransaction,
    this.searchQuery = '',
  });

  CashOutState copyWith({
    Position? userPosition,
    List<AgentModel>? nearbyAgents,
    AgentModel? selectedAgent,
    bool? isLoadingLocation,
    bool? isLoadingAgents,
    bool? isProcessingTransaction,
    String? errorMessage,
    CashOutTransaction? activeTransaction,
    String? searchQuery,
    bool clearError = false,
    bool clearAgent = false,
    bool clearTransaction = false,
  }) {
    return CashOutState(
      userPosition: userPosition ?? this.userPosition,
      nearbyAgents: nearbyAgents ?? this.nearbyAgents,
      selectedAgent: clearAgent ? null : (selectedAgent ?? this.selectedAgent),
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoadingAgents: isLoadingAgents ?? this.isLoadingAgents,
      isProcessingTransaction:
          isProcessingTransaction ?? this.isProcessingTransaction,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeTransaction: clearTransaction
          ? null
          : (activeTransaction ?? this.activeTransaction),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CashOutNotifier extends StateNotifier<CashOutState> {
  final GeoService _geoService;
  final AgentService _agentService;
  final TransactionCodeService _txService;

  CashOutNotifier({
    required GeoService geoService,
    required AgentService agentService,
    required TransactionCodeService txService,
  })  : _geoService = geoService,
        _agentService = agentService,
        _txService = txService,
        super(const CashOutState());

  /// Get precise user location then load nearby agents.
  Future<void> initialize() async {
    state = state.copyWith(isLoadingLocation: true, clearError: true);

    try {
      final position = await _geoService.getCurrentLocation();
      state = state.copyWith(
        userPosition: position,
        isLoadingLocation: false,
        isLoadingAgents: true,
      );
      await _loadNearbyAgents(position!);
    }
    // ── Catch geolocator's own exception types directly ──────────────────────
    // Both are exported by package:geolocator — no custom redeclaration needed.
    on LocationServiceDisabledException {
      state = state.copyWith(
        isLoadingLocation: false,
        errorMessage: 'Please enable location services to find nearby agents.',
      );
    } on PermissionDeniedException catch (e) {
      state = state.copyWith(
        isLoadingLocation: false,
        errorMessage: e.message, // .message is the field on geolocator's class
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingLocation: false,
        errorMessage: 'Unable to get your location. Please try again.',
      );
    }
  }

  Future<void> _loadNearbyAgents(Position position) async {
    state = state.copyWith(isLoadingAgents: true);
    try {
      final agents = await _agentService.getNearbyAgents(
        userPosition: position,
        radiusKm: 5.0,
      );
      state = state.copyWith(nearbyAgents: agents, isLoadingAgents: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingAgents: false,
        errorMessage: 'Unable to load agents. Please try again.',
      );
    }
  }

  void selectAgent(AgentModel agent) =>
      state = state.copyWith(selectedAgent: agent);

  void clearSelectedAgent() => state = state.copyWith(clearAgent: true);

  Future<void> searchAgents(String query) async {
    state = state.copyWith(searchQuery: query);
    if (state.userPosition == null) return;
    if (query.isEmpty) {
      await _loadNearbyAgents(state.userPosition!);
      return;
    }
    try {
      final agents = await _agentService.searchAgentsByAddress(
        query: query,
        userPosition: state.userPosition!,
      );
      state = state.copyWith(nearbyAgents: agents);
    } catch (_) {
      // keep current list on search failure
    }
  }

  /// Create a pending cash-out transaction and store the generated code.
  Future<CashOutTransaction?> createTransaction({
    required double amount,
    required String userId,
    required String userAccountNumber,
    required String userName,
  }) async {
    if (state.selectedAgent == null) return null;

    state = state.copyWith(isProcessingTransaction: true, clearError: true);

    try {
      final transaction = await _txService.createTransaction(
        userId: userId,
        agent: state.selectedAgent!,
        withdrawalAmount: amount,
        userAccountNumber: userAccountNumber,
        userName: userName,
      );
      state = state.copyWith(
        activeTransaction: transaction,
        isProcessingTransaction: false,
      );
      return transaction;
    } catch (e) {
      state = state.copyWith(
        isProcessingTransaction: false,
        errorMessage: 'Transaction failed. Please try again.',
      );
      return null;
    }
  }

  /// User taps "Received" — mark the transaction complete in Firestore.
  Future<void> confirmReceived() async {
    if (state.activeTransaction == null) return;
    try {
      await _txService.markTransactionCompleted(state.activeTransaction!.id);
    } catch (_) {
      // already recorded locally — ignore
    } finally {
      state = state.copyWith(clearTransaction: true);
    }
  }

  /// 15-minute timer expired — mark transaction expired in Firestore.
  Future<void> markExpired() async {
    if (state.activeTransaction == null) return;
    try {
      await _txService.markTransactionExpired(state.activeTransaction!.id);
    } catch (_) {
      // ignore
    } finally {
      state = state.copyWith(clearTransaction: true);
    }
  }

  String formatCode(String code) => _txService.formatCodeForDisplay(code);

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final cashOutProvider =
    StateNotifierProvider<CashOutNotifier, CashOutState>((ref) {
  return CashOutNotifier(
    geoService: GeoService(),
    agentService: AgentService(),
    txService: TransactionCodeService(),
  );
});
