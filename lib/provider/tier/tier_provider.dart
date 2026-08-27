import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:flutter_riverpod/legacy.dart';
/// State class for Tier management
class TierState {
  final TierLevel currentTier;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpgraded;
  final Map<String, bool> completedRequirements;

  const TierState({
    required this.currentTier,
    this.isLoading = false,
    this.error,
    this.lastUpgraded,
    this.completedRequirements = const {},
  });

  TierState copyWith({
    TierLevel? currentTier,
    bool? isLoading,
    String? error,
    DateTime? lastUpgraded,
    Map<String, bool>? completedRequirements,
  }) {
    return TierState(
      currentTier: currentTier ?? this.currentTier,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpgraded: lastUpgraded ?? this.lastUpgraded,
      completedRequirements: completedRequirements ?? this.completedRequirements,
    );
  }

  // Get the UpgradeTier object based on current tier
  UpgradeTier getTierObject() {
    switch (currentTier) {
      case TierLevel.basic:
        return UpgradeTier.basicTier();
      case TierLevel.pro:
        return UpgradeTier.proTier();
      case TierLevel.mega:
        return UpgradeTier.megaTier();
    }
  }

  // Get next tier if available
  UpgradeTier? getNextTier() {
    switch (currentTier) {
      case TierLevel.basic:
        return UpgradeTier.proTier();
      case TierLevel.pro:
        return UpgradeTier.megaTier();
      case TierLevel.mega:
        return null; // Already at max tier
    }
  }

  // Check if user can upgrade to the next tier
  bool canUpgrade() {
    return getNextTier() != null;
  }

  // Get tier benefits for current tier
  List<TierBenefit> getCurrentBenefits() {
    return getTierObject().benefits;
  }

  // Get tier requirements for next tier
  List<TierRequirement> getNextTierRequirements() {
    return getNextTier()?.requirements ?? [];
  }
}

/// Tier State Notifier - Manages tier state and persistence
class TierNotifier extends StateNotifier<TierState> {
  final StorageService _storageService;

  TierNotifier(this._storageService)
      : super(const TierState(currentTier: TierLevel.basic)) {
    _loadTierFromStorage();
  }

  // Load tier from storage on initialization
  Future<void> _loadTierFromStorage() async {
  try {
    final tierString = await _storageService.getCurrentTier();
    final tier = TierLevel.values.firstWhere(
      (e) => e.name == tierString,
      orElse: () => TierLevel.basic,
    );
    final lastUpgraded = await _storageService.getLastTierUpgradeDate();
    final requirements = await _storageService.getCompletedRequirements();

    state = state.copyWith(
      currentTier: tier,
      lastUpgraded: lastUpgraded,
      completedRequirements: requirements,
    );
  } catch (e) {
    state = state.copyWith(
      error: 'Failed to load tier: $e',
    );
  }
}

  // ---------------------------------------------------------------------------
  // SET TIER FROM ONBOARDING
  // Called by choose_tribe.dart immediately after the user picks a tier.
  // This is a LOCAL display cache of the tier the user selected during
  // onboarding (PRD §2.1.2: a new user may pick Basic/Pro/Mega directly). It
  // does NOT grant tiers — the server-authoritative grant lives on
  // UserModel.grantedTier (see SLICE 7 P0-3), and tier UPGRADES are recorded
  // server-side via AuthNotifier.selectTier (SLICE 8 MO-8.2/MO-8.3), never
  // simulated here.
  // ---------------------------------------------------------------------------
  Future<void> setTierFromOnboarding(int tierNumber) async {
    final TierLevel level;
    switch (tierNumber) {
      case 2:
        level = TierLevel.pro;
        break;
      case 3:
        level = TierLevel.mega;
        break;
      default:
        level = TierLevel.basic;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storageService.saveCurrentTier(level);
      state = state.copyWith(
        currentTier: level,
        lastUpgraded: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save tier: $e',
      );
    }
  }

  // Mark a requirement as completed
  Future<void> completeRequirement(String requirementId) async {
    try {
      final updatedRequirements = Map<String, bool>.from(state.completedRequirements);
      updatedRequirements[requirementId] = true;

      await _storageService.saveCompletedRequirements(updatedRequirements);

      state = state.copyWith(
        completedRequirements: updatedRequirements,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark requirement as completed: $e',
      );
    }
  }

  // Check if a specific requirement is completed
  bool isRequirementCompleted(String requirementId) {
    return state.completedRequirements[requirementId] ?? false;
  }

  // Reset tier (for testing or admin purposes)
  Future<void> resetTier() async {
    try {
      await _storageService.saveCurrentTier(TierLevel.basic);
      await _storageService.clearTierData();

      state = const TierState(currentTier: TierLevel.basic);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to reset tier: $e',
      );
    }
  }

  // Refresh tier state from storage
  Future<void> refresh() async {
    await _loadTierFromStorage();
  }
}

/// Provider for tier state
final tierProvider = StateNotifierProvider<TierNotifier, TierState>((ref) {
  return TierNotifier(StorageService.instance);
});

/// Convenience provider to get current tier level
final currentTierProvider = Provider<TierLevel>((ref) {
  return ref.watch(tierProvider).currentTier;
});

/// Convenience provider to check if user can upgrade
final canUpgradeTierProvider = Provider<bool>((ref) {
  return ref.watch(tierProvider).canUpgrade();
});

/// Convenience provider to get next tier
final nextTierProvider = Provider<UpgradeTier?>((ref) {
  return ref.watch(tierProvider).getNextTier();
});

/// Convenience provider to get current tier object
final currentTierObjectProvider = Provider<UpgradeTier>((ref) {
  return ref.watch(tierProvider).getTierObject();
});