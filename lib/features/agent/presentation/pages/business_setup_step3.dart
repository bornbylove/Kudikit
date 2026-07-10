import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

import 'package:kudipay/presentation/agent/agent_registration_widgets.dart';

// =============================================================================
// Step 3: Business Setup
// Operating days, hours, cash float, transaction limits, commission rate,
// and a live earnings estimate card.
// =============================================================================

class Step3BusinessSetupScreen extends ConsumerStatefulWidget {
  const Step3BusinessSetupScreen({super.key});

  @override
  ConsumerState<Step3BusinessSetupScreen> createState() => _Step3State();
}

class _Step3State extends ConsumerState<Step3BusinessSetupScreen> {
  late final TextEditingController _cashCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _commCtrl;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final app = ref.read(agentRegistrationProvider).application;
    _cashCtrl = TextEditingController(
        text: app.cashFloat > 0 ? app.cashFloat.toStringAsFixed(0) : '');
    _minCtrl = TextEditingController(
        text: app.minPerTransaction > 0
            ? app.minPerTransaction.toStringAsFixed(0)
            : '');
    _maxCtrl = TextEditingController(
        text: app.maxPerTransaction > 0
            ? app.maxPerTransaction.toStringAsFixed(0)
            : '');
    _commCtrl = TextEditingController(
        text: app.commissionRate > 0
            ? app.commissionRate.toStringAsFixed(1)
            : '');
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _commCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context,
      {required bool isOpening}) async {
    final notifier = ref.read(agentRegistrationProvider.notifier);
    final app = ref.read(agentRegistrationProvider).application;
    final current = isOpening ? app.openingTime : app.closingTime;
    final parts = current.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minPart = parts.length > 1 ? parts[1].split(' ')[0] : '00';
    final minute = int.tryParse(minPart) ?? 0;
    final isPm = current.contains('PM');

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isPm ? (hour == 12 ? 12 : hour + 12) : hour,
        minute: minute,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryTeal),
        ),
        child: child!,
      ),
    );

    if (picked != null && context.mounted) {
      final formatted = picked.format(context);
      if (isOpening) {
        notifier.updateOpeningTime(formatted);
      } else {
        notifier.updateClosingTime(formatted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentRegistrationProvider);
    final notifier = ref.read(agentRegistrationProvider.notifier);
    final app = state.application;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Text(
                  'Business Setup',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  'Configure your operating hours and transaction limits.',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: AppColors.textGrey,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // ── Operating days + hours ────────────────────────────────────
                KudiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KudiFieldLabel('Operating Days'),
                      SizedBox(height: AppLayout.scaleHeight(context, 10)),

                      // Day chips — LayoutBuilder makes them fit any width
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final chipW = (constraints.maxWidth -
                                  AppLayout.scaleWidth(ctx, 48)) /
                              7;
                          return Row(
                            children: _days.map((day) {
                              final selected = app.operatingDays.contains(day);
                              return GestureDetector(
                                onTap: () => notifier.toggleOperatingDay(day),
                                child: Container(
                                  width: chipW,
                                  height: chipW,
                                  margin: EdgeInsets.only(
                                      right: AppLayout.scaleWidth(ctx, 6)),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primaryTeal
                                        : AppColors.backgroundScreen,
                                    borderRadius: BorderRadius.circular(
                                        AppLayout.scaleWidth(ctx, 8)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: AppLayout.fontSize(ctx, 11),
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 14)),

                      // Tappable opening / closing time display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _pickTime(context, isOpening: true),
                            child: Text(
                              app.openingTime,
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: AppColors.textGrey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _pickTime(context, isOpening: false),
                            child: Text(
                              app.closingTime,
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: AppColors.textGrey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // ── Cash float + limits ───────────────────────────────────────
                KudiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KudiFieldLabel('Cash Float'),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      _AmountField(
                        hint: '50,000',
                        controller: _cashCtrl,
                        onChanged: (v) =>
                            notifier.updateCashFloat(double.tryParse(v) ?? 0),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),

                      // Min / Max side by side
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Min per Transaction',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 12),
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 6)),
                                _AmountField(
                                  hint: '',
                                  controller: _minCtrl,
                                  onChanged: (v) =>
                                      notifier.updateMinPerTransaction(
                                          double.tryParse(v) ?? 0),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Max per Transaction',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 12),
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 6)),
                                _AmountField(
                                  hint: '',
                                  controller: _maxCtrl,
                                  onChanged: (v) =>
                                      notifier.updateMaxPerTransaction(
                                          double.tryParse(v) ?? 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),

                      KudiFieldLabel('Commission Rate'),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      TextField(
                        controller: _commCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        onChanged: (v) => notifier
                            .updateCommissionRate(double.tryParse(v) ?? 1.5),
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: '1.5',
                          hintStyle: TextStyle(
                            color: AppColors.textLight,
                            fontSize: AppLayout.fontSize(context, 14),
                          ),
                          suffixText: '%',
                          suffixStyle: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: AppColors.textGrey,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundScreen,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 14),
                            vertical: AppLayout.scaleHeight(context, 13),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 10)),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 10)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 10)),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // ── Earnings Estimation ───────────────────────────────────────
                KudiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimation',
                        style: TextStyle(
                          fontFamily: 'PolySans',
                          fontSize: AppLayout.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 14)),
                      Row(
                        children: [
                          _EstCol(
                            label: 'Per withdrawal',
                            value: '₦${_fmt(app.estimatedPerWithdrawal)}',
                          ),
                          _EstCol(
                            label: 'Daily',
                            value: '₦${_fmt(app.estimatedDaily)}',
                          ),
                          _EstCol(
                            label: 'Monthly estimate',
                            value: '₦${_fmt(app.estimatedMonthly)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 100)),
              ],
            ),
          ),
        ),
        KudiPrimaryButton(
          label: 'Continue',
          onPressed: app.isStep3Valid ? () => notifier.nextStep() : null,
        ),
      ],
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v == 0) return '0';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Local sub-widgets ──────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppLayout.scaleWidth(context, 10);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: '₦ ',
        prefixStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: AppColors.textGrey,
        ),
        hintStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: AppLayout.fontSize(context, 14),
        ),
        filled: true,
        fillColor: AppColors.backgroundScreen,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 14),
          vertical: AppLayout.scaleHeight(context, 13),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide:
              const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}

class _EstCol extends StatelessWidget {
  final String label;
  final String value;

  const _EstCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 11),
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 4)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
