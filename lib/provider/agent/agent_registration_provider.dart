import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/agent/agent_application_model.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── Registration State ────────────────────────────────────────────────────────

class AgentRegistrationState {
  final AgentApplication application;
  final int currentStep; // 0–3
  final bool isLookingUpAccount;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;
  final String? accountLookupError;

  const AgentRegistrationState({
    this.application = const AgentApplication(),
    this.currentStep = 0,
    this.isLookingUpAccount = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.accountLookupError,
  });

  // Progress fraction shown in the circular badge
  double get progressPercent => (currentStep + 1) / 4;

  AgentRegistrationState copyWith({
    AgentApplication? application,
    int? currentStep,
    bool? isLookingUpAccount,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    String? accountLookupError,
    bool clearError = false,
    bool clearAccountError = false,
  }) {
    return AgentRegistrationState(
      application: application ?? this.application,
      currentStep: currentStep ?? this.currentStep,
      isLookingUpAccount: isLookingUpAccount ?? this.isLookingUpAccount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      accountLookupError: clearAccountError
          ? null
          : (accountLookupError ?? this.accountLookupError),
    );
  }
}

// ── Registration Notifier ─────────────────────────────────────────────────────

class AgentRegistrationNotifier extends StateNotifier<AgentRegistrationState> {
  AgentRegistrationNotifier() : super(const AgentRegistrationState());

  final _firestore = FirebaseFirestore.instance;

  // ── Navigation ─────────────────────────────────────────────────────────────

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  // ── Step 1: Business Info ──────────────────────────────────────────────────

  void updateBusinessName(String v) => state =
      state.copyWith(application: state.application.copyWith(businessName: v));

  void updateBusinessType(BusinessType t) => state =
      state.copyWith(application: state.application.copyWith(businessType: t));

  void updateBusinessDescription(String v) => state = state.copyWith(
      application: state.application.copyWith(businessDescription: v));

  // ── Step 2: Location ───────────────────────────────────────────────────────

  void updateBusinessAddress(String v) => state = state.copyWith(
      application: state.application.copyWith(businessAddress: v));

  void updateStorefrontPhoto(String url) => state = state.copyWith(
      application: state.application.copyWith(storefrontPhotoUrl: url));

  // ── Step 3: Business Setup ─────────────────────────────────────────────────

  void toggleOperatingDay(String day) {
    final days = List<String>.from(state.application.operatingDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    state = state.copyWith(
        application: state.application.copyWith(operatingDays: days));
  }

  void updateOpeningTime(String v) => state =
      state.copyWith(application: state.application.copyWith(openingTime: v));

  void updateClosingTime(String v) => state =
      state.copyWith(application: state.application.copyWith(closingTime: v));

  void updateCashFloat(double v) => state =
      state.copyWith(application: state.application.copyWith(cashFloat: v));

  void updateMinPerTransaction(double v) => state = state.copyWith(
      application: state.application.copyWith(minPerTransaction: v));

  void updateMaxPerTransaction(double v) => state = state.copyWith(
      application: state.application.copyWith(maxPerTransaction: v));

  void updateCommissionRate(double v) => state = state.copyWith(
      application: state.application.copyWith(commissionRate: v));

  // ── Step 4: Bank Account ───────────────────────────────────────────────────

  void updateAccountNumber(String v) {
    state = state.copyWith(
      application:
          state.application.copyWith(accountNumber: v, accountName: ''),
      clearAccountError: true,
    );
    if (v.length == 10) lookupAccountName(v);
  }

  Future<void> lookupAccountName(String accountNumber) async {
    state = state.copyWith(isLookingUpAccount: true, clearAccountError: true);
    try {
      // Simulate network — replace with real bank API call
      await Future.delayed(const Duration(seconds: 1));
      const resolvedName = 'PETER AKINOLA';
      state = state.copyWith(
        isLookingUpAccount: false,
        application: state.application.copyWith(accountName: resolvedName),
      );
    } catch (_) {
      state = state.copyWith(
        isLookingUpAccount: false,
        accountLookupError: 'Could not verify account. Check the number.',
      );
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> submitApplication({required String userId}) async {
    if (!state.application.isFullyValid) {
      state =
          state.copyWith(errorMessage: 'Please complete all required fields.');
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final app = state.application.copyWith(
        userId: userId,
        status: ApplicationStatus.submitted,
        submittedAt: DateTime.now(),
      );
      await _firestore.collection('agent_applications').add(app.toMap());
      state = state.copyWith(isSubmitting: false, isSubmitted: true);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Submission failed. Please try again.',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void reset() => state = const AgentRegistrationState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final agentRegistrationProvider =
    StateNotifierProvider<AgentRegistrationNotifier, AgentRegistrationState>(
  (ref) => AgentRegistrationNotifier(),
);

// ── Dashboard State & Notifier ────────────────────────────────────────────────

class AgentDashboardState {
  final bool isAvailable;
  final double todayCommission;
  final int todayTransactions;
  final double totalAmount;
  final List<Map<String, dynamic>> pendingRequests;

  const AgentDashboardState({
    this.isAvailable = true,
    this.todayCommission = 4350,
    this.todayTransactions = 13,
    this.totalAmount = 245000,
    this.pendingRequests = const [],
  });

  AgentDashboardState copyWith({
    bool? isAvailable,
    double? todayCommission,
    int? todayTransactions,
    double? totalAmount,
    List<Map<String, dynamic>>? pendingRequests,
  }) {
    return AgentDashboardState(
      isAvailable: isAvailable ?? this.isAvailable,
      todayCommission: todayCommission ?? this.todayCommission,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      totalAmount: totalAmount ?? this.totalAmount,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

class AgentDashboardNotifier extends StateNotifier<AgentDashboardState> {
  AgentDashboardNotifier() : super(const AgentDashboardState()) {
    _loadMockRequests();
  }

  void _loadMockRequests() {
    state = state.copyWith(pendingRequests: [
      {
        'name': 'Tunde A.',
        'amount': 15000.0,
        'commission': 225.0,
        'distance': '0.3 km',
        'timeAgo': '2mins ago',
      }
    ]);
  }

  void toggleAvailability() {
    state = state.copyWith(isAvailable: !state.isAvailable);
    // TODO: update Firestore agent document
  }

  void acceptRequest(Map<String, dynamic> request) {
    final updated = List<Map<String, dynamic>>.from(state.pendingRequests)
      ..remove(request);
    state = state.copyWith(pendingRequests: updated);
    // TODO: notify requesting user via FCM
  }
}

final agentDashboardProvider =
    StateNotifierProvider<AgentDashboardNotifier, AgentDashboardState>(
  (ref) => AgentDashboardNotifier(),
);
