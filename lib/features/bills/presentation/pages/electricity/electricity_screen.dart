// ============================================================================
// lib/presentation/bill/electricity/electricity_screen.dart
// Electricity bill payment screen — matches designs exactly.
//
// Screens covered:
//   Image 5  ? Main form (provider, prepaid/postpaid toggle, meter, amounts)
//   Image 3  ? After valid meter entered (account detail + amount chips)
//   Image 4  ? Provider selection bottom sheet
//   Image 1  ? Confirm bottom sheet (single Pay button)
//   Image 2  ? Confirm bottom sheet (Recheck + Send)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/transaction_pin_bottom_sheet.dart';
import 'package:kudipay/model/electricity/electricity_model.dart';
import 'package:kudipay/features/bills/presentation/pages/bill_payment_success.dart';
import 'package:kudipay/provider/electricity/electricity_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';

class ElectricityScreen extends ConsumerStatefulWidget {
  const ElectricityScreen({super.key});

  @override
  ConsumerState<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends ConsumerState<ElectricityScreen> {
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(electricityProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _openProviderSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ProviderSelectionSheet(),
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
      builder: (_) => const _ConfirmPaymentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(electricityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --------------------------------------------------
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
                    'Electricity',
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
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),

                    // -- Select Provider ---------------------------------
                    Text(
                      'Select Provider',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),

                    GestureDetector(
                      onTap: _openProviderSheet,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppLayout.scaleWidth(context, 16),
                          vertical: AppLayout.scaleHeight(context, 14),
                        ),
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
                        child: Row(
                          children: [
                            _ProviderLogo(provider: state.selectedProvider),
                            SizedBox(width: AppLayout.scaleWidth(context, 12)),
                            Expanded(
                              child: Text(
                                state.selectedProvider.name,
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

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Prepaid / Postpaid Toggle ---------------------
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                          _MeterTypeTab(
                            label: 'Prepaid',
                            isSelected: state.meterType == MeterType.prepaid,
                            onTap: () => ref
                                .read(electricityProvider.notifier)
                                .setMeterType(MeterType.prepaid),
                          ),
                          _MeterTypeTab(
                            label: 'Postpaid',
                            isSelected: state.meterType == MeterType.postpaid,
                            onTap: () => ref
                                .read(electricityProvider.notifier)
                                .setMeterType(MeterType.postpaid),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Meter / Account Number Card -------------------
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
                            'Meter / Account Number',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 6)),

                          // Meter input row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _meterController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(13),
                                  ],
                                  onChanged: (v) {
                                    ref
                                        .read(electricityProvider.notifier)
                                        .setMeterNumber(v);
                                  },
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 15),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Meter Number',
                                    hintStyle: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 15),
                                      color: const Color(0xFFBDBDBD),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    suffixIcon: state.isValidatingMeter
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
                                            ? const Icon(Icons.check_circle,
                                                color: Color(0xFF069494),
                                                size: 20)
                                            : null,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Beneficiaries link
                          if (state.meterNumber.isEmpty) ...[
                            SizedBox(height: AppLayout.scaleHeight(context, 8)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Beneficiaries',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 13),
                                  color: const Color(0xFF069494),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          // Account detail section
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
                              value: state.accountDetail!.name,
                            ),
                            _DetailRow(
                              label: 'Meter number',
                              value: state.accountDetail!.meterNumber,
                            ),
                            _DetailRow(
                              label: 'Meter type',
                              value: state.accountDetail!.meterType ==
                                      MeterType.prepaid
                                  ? 'Prepaid'
                                  : 'Postpaid',
                            ),
                            _DetailRow(
                              label: 'Provider',
                              value: state.accountDetail!.provider,
                            ),
                            _DetailRow(
                              label: 'Location',
                              value: state.accountDetail!.location,
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Amount Section ----------------------------------
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
                            'Amount',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),

                          // Amount input
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
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[\d,]')),
                                    ],
                                    onChanged: (v) {
                                      final cleaned = v.replaceAll(',', '');
                                      final parsed = double.tryParse(cleaned);
                                      if (parsed != null) {
                                        ref
                                            .read(electricityProvider.notifier)
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

                          // Balance label
                          SizedBox(height: AppLayout.scaleHeight(context, 6)),
                          Text(
                            'Balance: ? 50000.00',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 14)),

                          // Amount quick chips — 2 rows of 3
                          _AmountChipsGrid(
                            onAmountSelected: (amount) {
                              ref
                                  .read(electricityProvider.notifier)
                                  .setAmount(amount);
                              _amountController.text =
                                  _formatAmount(amount.toInt());
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 24)),
                  ],
                ),
              ),
            ),

            // -- Continue Button -----------------------------------------
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
                    disabledBackgroundColor: const Color(0xFFA8D5D5),
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
// _ProviderLogo
// ============================================================================

class _ProviderLogo extends StatelessWidget {
  final ElectricityProviderInfo provider;
  const _ProviderLogo({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0B2447),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 18),
            Text(
              provider.shortCode.length > 4
                  ? provider.shortCode.substring(0, 4)
                  : provider.shortCode,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _MeterTypeTab
// ============================================================================

class _MeterTypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeterTypeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF069494) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _DetailRow
// ============================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w400,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _AmountChipsGrid  — 2 rows × 3 cols
// ============================================================================

class _AmountChipsGrid extends StatelessWidget {
  final ValueChanged<double> onAmountSelected;

  const _AmountChipsGrid({required this.onAmountSelected});

  static const _amounts = [1000, 2000, 5000, 10000, 15000, 20000];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: _amounts
              .take(3)
              .map((a) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: a == _amounts[2]
                              ? 0
                              : AppLayout.scaleWidth(context, 8)),
                      child: _AmountChip(
                        amount: a,
                        onTap: () => onAmountSelected(a.toDouble()),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Row(
          children: _amounts
              .skip(3)
              .map((a) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: a == _amounts[5]
                              ? 0
                              : AppLayout.scaleWidth(context, 8)),
                      child: _AmountChip(
                        amount: a,
                        onTap: () => onAmountSelected(a.toDouble()),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _AmountChip({required this.amount, required this.onTap});

  String _format(int n) {
    if (n >= 1000) return '?${n ~/ 1000},000';
    return '?$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          children: [
            Text(
              _format(amount),
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 2)),
            Text(
              'Pay ${_format(amount)}',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 11),
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _ProviderSelectionSheet  (Image 4)
// ============================================================================

class _ProviderSelectionSheet extends ConsumerWidget {
  const _ProviderSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Provider',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 22, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),

            // Provider list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: electricityProviders.length,
                itemBuilder: (_, i) {
                  final p = electricityProviders[i];
                  return GestureDetector(
                    onTap: () {
                      ref.read(electricityProvider.notifier).setProvider(p);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 20),
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                      child: Row(
                        children: [
                          _ProviderLogo(provider: p),
                          SizedBox(width: AppLayout.scaleWidth(context, 14)),
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 15),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
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

class _ConfirmPaymentSheet extends ConsumerStatefulWidget {
  const _ConfirmPaymentSheet();

  @override
  ConsumerState<_ConfirmPaymentSheet> createState() =>
      _ConfirmPaymentSheetState();
}

class _ConfirmPaymentSheetState extends ConsumerState<_ConfirmPaymentSheet> {
  // When true, show Recheck + Send (Image 2 variant)
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(electricityProvider);
    final wallet = ref.watch(walletProvider);
    final formattedAmount = _formatCurrency(state.amount ?? 0);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 20),
            vertical: AppLayout.scaleHeight(context, 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Header row ------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Electricity',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 20, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // -- Amount ------------------------------------------------
              Text(
                '?$formattedAmount',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 28),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF069494),
                  fontFamily: 'PolySans',
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 4)),

              Text(
                state.selectedProvider.name,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: const Color(0xFF9E9E9E),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // -- Detail card -------------------------------------------
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Name',
                      value: state.accountDetail?.name ?? '-',
                    ),
                    _DetailRow(
                      label: 'Meter number',
                      value: state.meterNumber,
                    ),
                    _DetailRow(
                      label: 'Meter type',
                      value: state.meterType == MeterType.prepaid
                          ? 'Prepaid'
                          : 'Postpaid',
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // -- Paying From ------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Paying from',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      wallet.initials,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wallet.accountName}  ${wallet.accountNumber}',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 2)),
                      Text(
                        '?${wallet.formattedBalance}',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // -- Action Buttons ----------------------------------------
              if (!_showActions)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showActions = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Pay',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    // Recheck
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF069494), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'Recheck',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 15),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF069494),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    // Send
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            final currentState = ref.read(electricityProvider);

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

                            if (pin == null || pin.length != 4) {
                              return; // user dismissed
                            }

                            nav.pop(); // close confirm sheet
                            await ref
                                .read(electricityProvider.notifier)
                                .processPayment(pin);

                            final updatedState = ref.read(electricityProvider);
                            if (updatedState.step == ElectricityStep.success) {
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => BillPaymentSuccessScreen(
                                    title: 'Electricity',
                                    providerName:
                                        currentState.selectedProvider.name,
                                    amount: currentState.amount ?? 0,
                                    transactionId:
                                        updatedState.result?.transactionId ??
                                            '',
                                    prepaidToken: currentState.meterType ==
                                            MeterType.prepaid
                                        ? updatedState.result?.token
                                        : null,
                                    details: [
                                      BillSuccessDetail(
                                        label: 'Name',
                                        value:
                                            currentState.accountDetail?.name ??
                                                '-',
                                      ),
                                      BillSuccessDetail(
                                        label: 'Meter number',
                                        value: currentState.meterNumber,
                                      ),
                                      BillSuccessDetail(
                                        label: 'Meter type',
                                        value: currentState.meterType ==
                                                MeterType.prepaid
                                            ? 'Prepaid'
                                            : 'Postpaid',
                                      ),
                                      BillSuccessDetail(
                                        label: 'Provider',
                                        value:
                                            currentState.selectedProvider.name,
                                      ),
                                      BillSuccessDetail(
                                        label: 'Transaction ID',
                                        value: updatedState
                                                .result?.transactionId ??
                                            '-',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF069494),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
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
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    final formatted = result.toString().split('').reversed.join('');
    return '$formatted.$decimal';
  }
}
