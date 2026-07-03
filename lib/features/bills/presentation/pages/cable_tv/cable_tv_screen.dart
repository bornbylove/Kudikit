// lib/presentation/bill/cable_tv/cable_tv_screen.dart
// Cable TV subscription payment screen — matches all 7 design images.
//
// FIXED (3 errors at the ref.listen block):
//   The compiler reports that `prev` (typed CableTvState?) can be null on the
//   first emission, so `prev?.selectedPlan` is fine, but the RHS of the != was
//   typed as Object because Dart widened the comparison operand when prev was
//   nullable. The fix: guard the whole block on `prev != null` first, then
//   access selectedPlan on the non-nullable prev. This also prevents the
//   spurious "getter 'selectedPlan' isn't defined for type Object" error caused
//   by the type widening.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/transaction_pin_bottom_sheet.dart';
import 'package:kudipay/model/cable_tv/cable_tv_model.dart';
import 'package:kudipay/features/bills/presentation/pages/bill_payment_success.dart';
import 'package:kudipay/provider/cable_tv/cable_tv_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';

// ============================================================================
// CableTvBillerScreen  (Image 12)
// ============================================================================

class CableTvBillerScreen extends ConsumerWidget {
  const CableTvBillerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
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
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_left,
                            size: 28, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  Text(
                    'TV Cable',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'PolySans',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Biller',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: cableTvProviders.map((provider) {
                    final isLast = provider == cableTvProviders.last;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(cableTvProvider.notifier)
                                .setProvider(CableTvProviderInfo(
                                  provider: provider.provider,
                                  name: provider.name,
                                ));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CableTvScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 16),
                              vertical: AppLayout.scaleHeight(context, 16),
                            ),
                            child: Row(
                              children: [
                                _ProviderAvatar(provider: provider),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 14)),
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 15),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    size: 20, color: Color(0xFF9E9E9E)),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: const Color(0xFFF0F0F0),
                            indent: AppLayout.scaleWidth(context, 16),
                            endIndent: AppLayout.scaleWidth(context, 16),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CableTvScreen  (Images 11, 9, 8, 7)
// ============================================================================

class CableTvScreen extends ConsumerStatefulWidget {
  const CableTvScreen({super.key});

  @override
  ConsumerState<CableTvScreen> createState() => _CableTvScreenState();
}

class _CableTvScreenState extends ConsumerState<CableTvScreen> {
  final TextEditingController _iucController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(cableTvProvider);
      if (state.selectedPlan != null) {
        _amountController.text =
            _formatAmount(state.selectedPlan!.amount.toInt());
      }
    });
  }

  @override
  void dispose() {
    _iucController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _openPlanSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlanSelectionSheet(),
    );
  }

  void _showConfirmSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ConfirmCableTvSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cableTvProvider);

    // FIXED: Guard prev != null before comparing its selectedPlan field.
    // Previously Dart inferred prev as CableTvState? and widened the != operand
    // to Object, causing "getter selectedPlan isn't defined for Object" and two
    // null-safety errors. Checking prev != null first gives a non-nullable
    // CableTvState for the comparison.
    ref.listen<CableTvState>(cableTvProvider, (prev, next) {
      if (next.selectedPlan != null &&
          prev != null &&
          prev.selectedPlan != next.selectedPlan) {
        _amountController.text =
            _formatAmount(next.selectedPlan!.amount.toInt());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar ----------------------------------------------
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
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_left,
                            size: 28, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  Text(
                    'TV Cable',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      fontFamily: 'PolySans',
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),

                    // -- Provider header chip -------------------------
                    Row(
                      children: [
                        _ProviderAvatar(provider: state.selectedProvider),
                        SizedBox(width: AppLayout.scaleWidth(context, 10)),
                        Text(
                          state.selectedProvider.name,
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Plan Selector --------------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Plan',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),
                          GestureDetector(
                            onTap: _openPlanSheet,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppLayout.scaleWidth(context, 12),
                                vertical: AppLayout.scaleHeight(context, 10),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      state.selectedPlan?.name ?? 'Select plan',
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 14),
                                        fontWeight: FontWeight.w400,
                                        color: state.selectedPlan != null
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFFBDBDBD),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 20, color: Color(0xFF9E9E9E)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- IUC Number Input -----------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: state.isIucInvalid
                            ? Border.all(color: Colors.red.shade400, width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter IUC number',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: state.isIucInvalid
                                  ? Colors.red.shade400
                                  : const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 6)),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _iucController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  onChanged: (v) {
                                    ref
                                        .read(cableTvProvider.notifier)
                                        .setIucNumber(v);
                                  },
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 15),
                                    fontWeight: FontWeight.w500,
                                    color: state.isIucInvalid
                                        ? Colors.red.shade400
                                        : const Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0000 000 000',
                                    hintStyle: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 15),
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    suffixIcon: state.isValidatingIuc
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF069494),
                                              ),
                                            ),
                                          )
                                        : state.accountDetail != null
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF069494),
                                                size: 20,
                                              )
                                            : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (state.isIucInvalid) ...[
                            SizedBox(height: AppLayout.scaleHeight(context, 4)),
                            Text(
                              'Invalid IUC, kindly try again',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 12),
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                          if (state.accountDetail != null) ...[
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 16)),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 12)),
                            Text(
                              'Account detail',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 10)),
                            _DetailRow(
                                label: 'Name',
                                value: state.accountDetail!.name),
                            _DetailRow(
                                label: 'Decoder',
                                value: state.accountDetail!.decoderNumber),
                            _DetailRow(
                                label: 'Provider',
                                value: state.accountDetail!.provider),
                            _DetailRow(
                                label: 'Current plan',
                                value: state.accountDetail!.currentPlan),
                            _DetailRow(
                              label: 'Status',
                              value: state.accountDetail!.isExpired
                                  ? 'Expired'
                                  : 'Active',
                              valueColor: state.accountDetail!.isExpired
                                  ? Colors.red.shade500
                                  : const Color(0xFF069494),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Amount ---------------------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter amount',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 6)),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 12),
                              vertical: AppLayout.scaleHeight(context, 10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 16),
                                    fontWeight: FontWeight.w500,
                                    color: state.amount != null
                                        ? const Color(0xFF1A1A2E)
                                        : const Color(0xFFBDBDBD),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (v) {
                                      final cleaned = v.replaceAll(',', '');
                                      final parsed = double.tryParse(cleaned);
                                      if (parsed != null) {
                                        ref
                                            .read(cableTvProvider.notifier)
                                            .setAmount(parsed);
                                      }
                                    },
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 16),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 24)),
                  ],
                ),
              ),
            ),

            // -- Continue Button --------------------------------------
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 12),
                AppLayout.scaleWidth(context, 20),
                AppLayout.scaleHeight(context, 24),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.canContinue ? _showConfirmSheet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    disabledBackgroundColor:
                        const Color(0xFF069494).withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
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

  String _formatAmount(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join('');
  }
}

// ============================================================================
// _ProviderAvatar
// ============================================================================

class _ProviderAvatar extends StatelessWidget {
  final CableTvProviderInfo provider;
  const _ProviderAvatar({required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (provider.provider) {
      case CableTvProvider.dstv:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0075BE),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text('DStv',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5)),
        );
      case CableTvProvider.gotv:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          alignment: Alignment.center,
          child: const Text('GOtv',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8001C),
                  letterSpacing: -0.5)),
        );
      case CableTvProvider.startimes:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF009944),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text('ST',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        );
    }
  }
}

// ============================================================================
// _DetailRow
// ============================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w400)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? const Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _PlanSelectionSheet  (Image 10)
// ============================================================================

class _PlanSelectionSheet extends ConsumerWidget {
  const _PlanSelectionSheet();

  String _formatAmount(double amount) {
    final int whole = amount.toInt();
    final str = whole.toString();
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cableTvProvider);
    final plans = state.availablePlans;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Plan',
                      style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 22, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: plans.length,
                itemBuilder: (_, i) {
                  final plan = plans[i];
                  final isSelected = state.selectedPlan?.id == plan.id;
                  return GestureDetector(
                    onTap: () {
                      ref.read(cableTvProvider.notifier).selectPlan(plan);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 20),
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                      child: Row(
                        children: [
                          _ProviderAvatar(
                            provider: CableTvProviderInfo(
                              provider: plan.provider,
                              name: state.selectedProvider.name,
                            ),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name,
                                    style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 15),
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF069494)
                                            : const Color(0xFF1A1A2E))),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 2)),
                                Text('?${_formatAmount(plan.amount)}.00',
                                    style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 13),
                                        color: const Color(0xFF9E9E9E))),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF069494), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _ConfirmCableTvSheet  (Image 6)
// ============================================================================

class _ConfirmCableTvSheet extends ConsumerWidget {
  const _ConfirmCableTvSheet();

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final result = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(whole[i]);
      count++;
    }
    return '${result.toString().split('').reversed.join('')}.$decimal';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cableTvProvider);
    final wallet = ref.watch(walletProvider);
    final formattedAmount =
        _formatCurrency(state.selectedPlan?.amount ?? state.amount ?? 0);

    return SafeArea(
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 20),
            vertical: AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cable Tv',
                      style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: const Color(0xFF9E9E9E))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 20, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text('?$formattedAmount',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 28),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF069494),
                      fontFamily: 'PolySans')),
              SizedBox(height: AppLayout.scaleHeight(context, 4)),
              Text(state.selectedProvider.name,
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: const Color(0xFF9E9E9E))),
              if (state.selectedPlan != null)
                Text(state.selectedPlan!.name,
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: const Color(0xFF9E9E9E))),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _DetailRow(
                        label: 'Decoder',
                        value: state.accountDetail?.decoderNumber ?? '-'),
                    _DetailRow(
                        label: 'Name', value: state.accountDetail?.name ?? '-'),
                  ],
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 20, color: Color(0xFF9E9E9E)),
                    SizedBox(width: AppLayout.scaleWidth(context, 10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-Renew',
                              style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 14),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1A1A2E))),
                          Text('Automatically renew this plan next month',
                              style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 12),
                                  color: const Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.autoRenew,
                      onChanged: (_) =>
                          ref.read(cableTvProvider.notifier).toggleAutoRenew(),
                      activeThumbColor: const Color(0xFF069494),
                      inactiveTrackColor: const Color(0xFFE0E0E0),
                      inactiveThumbColor: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Paying from',
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: const Color(0xFF9E9E9E))),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFF37474F),
                        borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(wallet.initials,
                        style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${wallet.accountName}  ${wallet.accountNumber}',
                          style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E))),
                      SizedBox(height: AppLayout.scaleHeight(context, 2)),
                      Text('?${wallet.formattedBalance}',
                          style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E))),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF069494), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text('Recheck',
                            style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF069494))),
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          final s = ref.read(cableTvProvider);

                          // Collect PIN before closing the confirm sheet
                          final pin = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            builder: (_) => TransactionPinBottomSheet(
                              title: '',
                              onSuccess: () {},
                            ),
                          );

                          if (pin == null || pin.length != 4)
                            return; // user dismissed

                          nav.pop(); // close confirm sheet
                          await ref
                              .read(cableTvProvider.notifier)
                              .processPayment(pin);

                          final updatedState = ref.read(cableTvProvider);
                          if (updatedState.step == CableTvStep.success) {
                            nav.push(MaterialPageRoute(
                              builder: (_) => BillPaymentSuccessScreen(
                                title: 'TV Cable',
                                providerName: s.selectedProvider.name,
                                amount: s.selectedPlan?.amount ?? s.amount ?? 0,
                                transactionId: updatedState.transactionId ??
                                    'TXN${DateTime.now().millisecondsSinceEpoch}',
                                details: [
                                  BillSuccessDetail(
                                      label: 'Plan',
                                      value: s.selectedPlan?.name ?? '-'),
                                  BillSuccessDetail(
                                      label: 'Decoder',
                                      value: s.accountDetail?.decoderNumber ??
                                          '-'),
                                  BillSuccessDetail(
                                      label: 'Name',
                                      value: s.accountDetail?.name ?? '-'),
                                  BillSuccessDetail(
                                      label: 'Provider',
                                      value: s.selectedProvider.name),
                                  if (s.autoRenew)
                                    const BillSuccessDetail(
                                        label: 'Auto-Renew',
                                        value: 'Enabled',
                                        valueColor: Color(0xFF069494)),
                                ],
                              ),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF069494),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text('Send',
                            style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
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
