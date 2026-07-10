// ============================================================================
//
// Screen 2 of the Buy Data flow.
//
// Features:
//   • Network + phone number display row (tap network to change)
//   • Tab bar: Daily | Weekly | Monthly
//   • Plan tiles with data badge, description, validity chip, price, check icon
//   • Animated selection highlight
//   • ConfirmDataBottomSheet: review + Recheck / Send
//   • DataSuccessBottomSheet: check icon + amount + "Add to beneficiary"
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/shared/widgets/network_logo.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/features/bills/domain/entities/bill_model.dart';
import 'package:kudipay/features/bills/presentation/pages/bill_transaction_detail.dart';
import 'package:kudipay/provider/provider.dart';

class DataPlansScreen extends ConsumerStatefulWidget {
  const DataPlansScreen({super.key});

  @override
  ConsumerState<DataPlansScreen> createState() => _DataPlansScreenState();
}

class _DataPlansScreenState extends ConsumerState<DataPlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _validityTab;
  static const _tabs = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _validityTab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _validityTab.dispose();
    super.dispose();
  }

  List<DataPlan> _filterPlans(List<DataPlan> plans, DataValidity validity) =>
      plans.where((p) => p.validity == validity).toList();

  void _onContinue() => _showConfirmSheet();

  void _showConfirmSheet() {
    final state = ref.read(dataProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmDataBottomSheet(
        phoneNumber: state.phoneNumber,
        network: state.selectedNetwork!,
        plan: state.selectedPlan!,
        onSend: () async {
          Navigator.pop(context); // close confirm
          await ref.read(dataProvider.notifier).processData();
          // Guard against widget being unmounted during the async gap
          if (mounted) _showSuccessOrError();
        },
      ),
    );
  }

  void _showSuccessOrError() {
    if (!mounted) return; // explicit guard at entry point
    final state = ref.read(dataProvider);
    if (state.step == DataStep.success) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => DataSuccessBottomSheet(
          plan: state.selectedPlan!,
          onDone: () {
            // Pop success ? plans ? phone ? home
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onDetails: () {
            Navigator.pop(context); // close success sheet
            final s = ref.read(dataProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillTransactionDetail(
                  title: 'Data Receipt',
                  transactionId: s.result?.transactionId ??
                      'TXN${DateTime.now().millisecondsSinceEpoch}',
                  billType: 'Data',
                  providerName: s.selectedNetwork?.displayName ?? '',
                  amount: s.selectedPlan?.price ?? 0,
                  transactionDate: s.result?.createdAt ?? DateTime.now(),
                  recipientNumber: s.phoneNumber,
                  recipientName: '',
                  extraDetails: {
                    'Plan': s.selectedPlan?.name ?? '',
                    'Validity': s.selectedPlan?.validityLabel ?? '',
                  },
                ),
              ),
            );
          },
        ),
      );
    } else if (state.step == DataStep.failed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      state.error ?? 'Transaction failed. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataProvider);
    // Use the dedicated isProcessing field — more reliable than comparing
    // DataStep, which may not stay in sync if state transitions change.
    final isProcessing = state.isProcessing;

    final dailyPlans = _filterPlans(state.plans, DataValidity.daily);
    final weeklyPlans = _filterPlans(state.plans, DataValidity.weekly);
    final monthlyPlans = _filterPlans(state.plans, DataValidity.monthly);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App bar --------------------------------------------------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 16),
                vertical: AppLayout.scaleHeight(context, 12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left,
                            size: 28, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  Text(
                    'Buy Data',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16)),
                    child: Column(
                      children: [
                        // -- Network + phone row --------------------------
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16),
                            vertical: AppLayout.scaleHeight(context, 14),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.wifi,
                                    color: AppColors.primaryTeal, size: 22),
                              ),
                              SizedBox(
                                  width: AppLayout.scaleWidth(context, 12)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Network  ',
                                        style: TextStyle(
                                          fontSize:
                                              AppLayout.fontSize(context, 12),
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      if (state.selectedNetwork != null)
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Row(
                                            children: [
                                              Text(
                                                state.selectedNetwork!
                                                    .displayName,
                                                style: TextStyle(
                                                  fontSize: AppLayout.fontSize(
                                                      context, 12),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryTeal,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.keyboard_arrow_down,
                                                size: 16,
                                                color: AppColors.primaryTeal,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatPhone(state.phoneNumber),
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 14)),

                        // -- Validity tabs --------------------------------
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _validityTab,
                            labelColor: AppColors.primaryTeal,
                            unselectedLabelColor: const Color(0xFF9E9E9E),
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 14),
                            indicatorColor: AppColors.primaryTeal,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: _tabs.map((t) => Tab(text: t)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 8)),

                  // -- Plans list ---------------------------------------
                  Expanded(
                    child: state.isLoadingPlans
                        // Fix 1: shimmer skeleton instead of spinner
                        ? const DataPlanShimmer()
                        : state.error != null && state.plans.isEmpty
                            // Fix 2: error state with a retry button instead
                            // of a dead-end message forcing back navigation
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          AppLayout.scaleWidth(context, 32)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wifi_off_rounded,
                                          size:
                                              AppLayout.scaleWidth(context, 56),
                                          color: Colors.grey[400]),
                                      SizedBox(
                                          height: AppLayout.scaleHeight(
                                              context, 16)),
                                      Text(
                                        'Failed to load plans',
                                        style: TextStyle(
                                          fontSize:
                                              AppLayout.fontSize(context, 16),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(
                                          height: AppLayout.scaleHeight(
                                              context, 8)),
                                      Text(
                                        // Sanitise: the generic catch in the
                                        // notifier may write e.toString() which
                                        // leaks internal exception details.
                                        (state.error != null &&
                                                !state.error!
                                                    .toLowerCase()
                                                    .contains('exception') &&
                                                !state.error!
                                                    .toLowerCase()
                                                    .contains('error:'))
                                            ? state.error!
                                            : 'Could not load plans. Please check your connection and try again.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              AppLayout.fontSize(context, 13),
                                          color: const Color(0xFF9E9E9E),
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(
                                          height: AppLayout.scaleHeight(
                                              context, 20)),
                                      ElevatedButton.icon(
                                        onPressed: () => ref
                                            .read(dataProvider.notifier)
                                            .proceedToSelectPlan(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryTeal,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppLayout.scaleWidth(
                                                    context, 28)),
                                          ),
                                        ),
                                        icon: const Icon(Icons.refresh,
                                            color: Colors.white, size: 18),
                                        label: const Text('Try Again',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : state.plans.isEmpty
                                ? Center(
                                    child: Text(
                                      'No plans available for this network.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 14),
                                        color: const Color(0xFF9E9E9E),
                                        height: 1.5,
                                      ),
                                    ),
                                  )
                                : TabBarView(
                                    controller: _validityTab,
                                    children: [
                                      _PlanList(
                                        plans: dailyPlans,
                                        selectedPlanId: state.selectedPlan?.id,
                                        onSelect: (p) => ref
                                            .read(dataProvider.notifier)
                                            .selectPlan(p),
                                        emptyMessage:
                                            'No daily plans available',
                                      ),
                                      _PlanList(
                                        plans: weeklyPlans,
                                        selectedPlanId: state.selectedPlan?.id,
                                        onSelect: (p) => ref
                                            .read(dataProvider.notifier)
                                            .selectPlan(p),
                                        emptyMessage:
                                            'No weekly plans available',
                                      ),
                                      _PlanList(
                                        plans: monthlyPlans,
                                        selectedPlanId: state.selectedPlan?.id,
                                        onSelect: (p) => ref
                                            .read(dataProvider.notifier)
                                            .selectPlan(p),
                                        emptyMessage:
                                            'No monthly plans available',
                                      ),
                                    ],
                                  ),
                  ),
                ],
              ),
            ),

            // -- Continue button ------------------------------------------
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 12),
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 24),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: state.canProceedFromPlan && !isProcessing
                      ? _onContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    disabledBackgroundColor:
                        AppColors.primaryTeal.withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: isProcessing
                      ? const AppLoadingIndicator.button()
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String phone) {
    final d = phone.replaceAll(' ', '');
    if (d.length == 11) {
      return '${d.substring(0, 4)} ${d.substring(4, 7)} ${d.substring(7)}';
    }
    return phone;
  }
}

// ============================================================================
// _PlanList
// ============================================================================

class _PlanList extends StatelessWidget {
  final List<DataPlan> plans;
  final String? selectedPlanId;
  final ValueChanged<DataPlan> onSelect;
  final String emptyMessage;

  const _PlanList({
    required this.plans,
    required this.selectedPlanId,
    required this.onSelect,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: const Color(0xFF9E9E9E),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 8),
      ),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final plan = plans[i];
        return _DataPlanTile(
          plan: plan,
          isSelected: selectedPlanId == plan.id,
          onTap: () => onSelect(plan),
        );
      },
    );
  }
}

// ============================================================================
// _DataPlanTile
// ============================================================================

class _DataPlanTile extends StatelessWidget {
  final DataPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _DataPlanTile({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 14),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Data size badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal
                    : const Color(0xFFF0F7F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  plan.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 14)),

            // Description + validity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryTeal.withValues(alpha: 0.15)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Valid for ${plan.validityLabel}',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 11),
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryTeal
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Price + check
            Text(
              '?${NumberFormat('#,###').format(plan.price)}',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primaryTeal
                    : const Color(0xFF1A1A2E),
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              const Icon(Icons.check_circle,
                  color: AppColors.primaryTeal, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ConfirmDataBottomSheet
// ============================================================================

class ConfirmDataBottomSheet extends ConsumerWidget {
  final String phoneNumber;
  final NetworkProvider network;
  final DataPlan plan;
  final VoidCallback onSend;

  const ConfirmDataBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.network,
    required this.plan,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final displayName =
        '${(userInfo?.firstName ?? 'MICHAEL').toUpperCase()} ASUQUO TOLUWALASE';
    final fmt = NumberFormat('#,###', 'en_NG');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 20),
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // "For data" + close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'For data',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 22, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // Amount
              Text(
                '?${fmt.format(plan.price)}',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 36),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: const Color(0xFF9E9E9E),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // Details card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 14),
                ),
                child: Column(
                  children: [
                    _Row(label: 'To', value: _fmt11(phoneNumber)),
                    const Divider(height: 20, color: Color(0xFFEEEEEE)),
                    _Row(
                      label: 'Network',
                      value: network.displayName,
                      trailing: NetworkLogo(network: network, size: 22),
                    ),
                    const Divider(height: 20, color: Color(0xFFEEEEEE)),
                    _Row(label: 'Validity', value: plan.validityLabel),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Paying from
              _PayingFromRow(displayName: displayName),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        side: const BorderSide(
                            color: AppColors.primaryTeal, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Recheck',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        backgroundColor: AppColors.primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt11(String phone) {
    final d = phone.replaceAll(' ', '');
    if (d.length == 11) {
      return '${d.substring(0, 4)} ${d.substring(4, 7)} ${d.substring(7)}';
    }
    return phone;
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const _Row({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        const Spacer(),
        if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _PayingFromRow extends ConsumerWidget {
  final String displayName;
  const _PayingFromRow({required this.displayName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paying from',
          style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: const Color(0xFF9E9E9E)),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF8A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    wallet.initials,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${wallet.accountName}  ${wallet.accountNumber}',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '? ${wallet.formattedBalance}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DataSuccessBottomSheet
// ============================================================================

class DataSuccessBottomSheet extends StatefulWidget {
  final DataPlan plan;
  final VoidCallback onDone;
  final VoidCallback onDetails;

  const DataSuccessBottomSheet({
    super.key,
    required this.plan,
    required this.onDone,
    required this.onDetails,
  });

  @override
  State<DataSuccessBottomSheet> createState() => _DataSuccessBottomSheetState();
}

class _DataSuccessBottomSheetState extends State<DataSuccessBottomSheet> {
  bool _addToBeneficiary = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_NG');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 20),
            AppLayout.scaleWidth(context, 24),
            AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Check + amount
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryTeal, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    '-?${fmt.format(widget.plan.price)}',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 22),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              Text(
                'Data request successfully submitted',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.plan.description} will be activated shortly',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: const Color(0xFF9E9E9E),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // Add to beneficiary
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Add to beneficiary',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _addToBeneficiary,
                          onChanged: (val) =>
                              setState(() => _addToBeneficiary = val),
                          activeThumbColor: AppColors.primaryTeal,
                        ),
                      ],
                    ),
                    if (_addToBeneficiary) ...[
                      SizedBox(height: AppLayout.scaleHeight(context, 10)),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1A1A2E)),
                        decoration: InputDecoration(
                          hintText: 'Enter beneficiary name',
                          hintStyle: const TextStyle(
                              fontSize: 14, color: Color(0xFFBDBDBD)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.primaryTeal),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDetails,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        side: const BorderSide(
                            color: AppColors.primaryTeal, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onDone,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        backgroundColor: AppColors.primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
