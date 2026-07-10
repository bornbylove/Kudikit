// lib/presentation/transaction/transaction_filter_screen.dart
//
// Full-page filter screen for the Transactions tab.
// Called via Navigator.push from TransactionsScreen (_showFilterDialog replaced
// by a push to this screen).
//
// Design (from mockups):
//   Image 1 — Date Range preset dropdown (default: Last 7 Days), sticky
//              bottom bar with Clear All + Apply Filter
//   Image 2 — Custom date range: Start Date + End Date date-picker fields
//              appear inside the card; Apply Filter greyed out until both
//              dates are filled.
//
// State management: Riverpod — local draft (_filterDraftProvider) scoped to
// this ProviderScope; writes to global transactionFilterProvider on Apply.
// Responsive: uses AppLayout helpers from core/utils/responsive.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transaction/domain/entities/transaction_model.dart';
import 'package:kudipay/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:flutter_riverpod/legacy.dart'; // keep existing
// ---------------------------------------------------------------------------
// Local enums & draft model
// ---------------------------------------------------------------------------

enum DateRangeOption {
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  last3Months('Last 3 Months'),
  custom('Custom');

  final String label;
  const DateRangeOption(this.label);
}

class FilterDraft {
  final DateRangeOption dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final TransactionStatus? status;

  const FilterDraft({
    this.dateRange = DateRangeOption.last7Days,
    this.customStart,
    this.customEnd,
    this.status,
  });

  FilterDraft copyWith({
    DateRangeOption? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    TransactionStatus? status,
    bool clearCustomStart = false,
    bool clearCustomEnd = false,
    bool clearStatus = false,
  }) =>
      FilterDraft(
        dateRange: dateRange ?? this.dateRange,
        customStart:
            clearCustomStart ? null : (customStart ?? this.customStart),
        customEnd: clearCustomEnd ? null : (customEnd ?? this.customEnd),
        status: clearStatus ? null : (status ?? this.status),
      );

  /// Apply button is disabled when Custom is chosen but dates not yet filled.
  bool get applyEnabled {
    if (dateRange == DateRangeOption.custom) {
      return customStart != null && customEnd != null;
    }
    return true;
  }

  static const FilterDraft cleared = FilterDraft();
}

// ---------------------------------------------------------------------------
// Local provider — intentionally NOT exported; only used inside this file.
// The ProviderScope override in TransactionFilterScreen keeps it scoped.
// ---------------------------------------------------------------------------

final _filterDraftProvider =
    StateProvider<FilterDraft>((ref) => const FilterDraft());

// ---------------------------------------------------------------------------
// Screen entry point — wraps its own ProviderScope so the draft is disposed
// when the route is popped and never leaks into the global scope.
// ---------------------------------------------------------------------------

class TransactionFilterScreen extends StatelessWidget {
  const TransactionFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Seed the draft from the currently-applied global filter.
      // We read (not watch) so the draft is only seeded once on creation.
      overrides: [
        _filterDraftProvider.overrideWith((ref) {
          final global = ref.read(transactionFilterProvider);

          return FilterDraft(
            dateRange: _mapToRange(global),
            customStart: global.startDate,
            customEnd: global.endDate,
            status: global.status,
          );
        })
      ],
      child: const _FilterScreenBody(),
    );
  }
}

DateRangeOption _mapToRange(TransactionFilter filter) {
  if (filter.startDate == null || filter.endDate == null) {
    return DateRangeOption.last7Days;
  }

  final now = DateTime.now();
  final diff = now.difference(filter.startDate!).inDays;

  if (diff <= 7) return DateRangeOption.last7Days;
  if (diff <= 30) return DateRangeOption.last30Days;
  if (diff <= 90) return DateRangeOption.last3Months;

  return DateRangeOption.custom;
}
// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _FilterScreenBody extends ConsumerWidget {
  const _FilterScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(_filterDraftProvider);
    final isTablet = AppLayout.isTablet(context);
    final hPad = AppLayout.scaleWidth(context, isTablet ? 24 : 16);
    final vPad = AppLayout.scaleHeight(context, 16);

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _FilterAppBar(isTablet: isTablet),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateRangeCard(draft: draft, isTablet: isTablet),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _StatusCard(draft: draft, isTablet: isTablet),
                ],
              ),
            ),
          ),
          _BottomBar(draft: draft, isTablet: isTablet),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _FilterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isTablet;
  const _FilterAppBar({required this.isTablet});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundScreen,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.textDark,
          size: AppLayout.scaleWidth(context, isTablet ? 22 : 18),
        ),
        onPressed: () => Navigator.maybePop(context),
        splashRadius: 22,
      ),
      title: Text(
        'Filter',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, isTablet ? 20 : 17),
          fontWeight: FontWeight.w600,
          fontFamily: 'PolySans',
        ),
      ),
      centerTitle: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Date Range Card
// ---------------------------------------------------------------------------

class _DateRangeCard extends ConsumerWidget {
  final FilterDraft draft;
  final bool isTablet;

  const _DateRangeCard({required this.draft, required this.isTablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelSz = AppLayout.fontSize(context, isTablet ? 14 : 12);
    final valueSz = AppLayout.fontSize(context, isTablet ? 15 : 14);
    final cardPadH = AppLayout.scaleWidth(context, 16);
    final cardPadV = AppLayout.scaleHeight(context, 16);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: cardPadH, vertical: cardPadV),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'Date Range', fontSize: labelSz),
          SizedBox(height: AppLayout.scaleHeight(context, 10)),

          // Dropdown
          _AppDropdown<DateRangeOption>(
            value: draft.dateRange,
            items: DateRangeOption.values,
            labelOf: (o) => o.label,
            valueFontSize: valueSz,
            onChanged: (picked) {
              if (picked == null) return;
              ref.read(_filterDraftProvider.notifier).state = draft.copyWith(
                dateRange: picked,
                clearCustomStart: picked != DateRangeOption.custom,
                clearCustomEnd: picked != DateRangeOption.custom,
              );
            },
          ),

          // Custom date fields — animated in/out
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: draft.dateRange == DateRangeOption.custom
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),
                      _SectionLabel(text: 'Start Date', fontSize: labelSz),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      _DateField(
                        value: draft.customStart,
                        hint: 'dd/mm/yy',
                        valueFontSize: valueSz,
                        onPicked: (d) {
                          if (draft.customStart != null &&
                              d.isBefore(draft.customStart!)) {
                            return;
                          }

                          ref.read(_filterDraftProvider.notifier).state =
                              draft.copyWith(customEnd: d);
                        },
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 14)),
                      _SectionLabel(text: 'End Date', fontSize: labelSz),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      _DateField(
                        value: draft.customEnd,
                        hint: 'dd/mm/yy',
                        valueFontSize: valueSz,
                        firstDate: draft.customStart,
                        onPicked: (d) {
                          if (draft.customStart != null &&
                              d.isBefore(draft.customStart!)) {
                            return;
                          }

                          ref.read(_filterDraftProvider.notifier).state =
                              draft.copyWith(customEnd: d);
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Card
// ---------------------------------------------------------------------------

class _StatusCard extends ConsumerWidget {
  final FilterDraft draft;
  final bool isTablet;

  const _StatusCard({required this.draft, required this.isTablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelSz = AppLayout.fontSize(context, isTablet ? 14 : 12);
    final chipSz = AppLayout.fontSize(context, isTablet ? 13 : 12);

    // null → "All"
    const options = <TransactionStatus?>[
      null,
      TransactionStatus.successful,
      TransactionStatus.failed,
      TransactionStatus.pending,
    ];

    const labels = <TransactionStatus?, String>{
      null: 'All',
      TransactionStatus.successful: 'Successful',
      TransactionStatus.failed: 'Failed',
      TransactionStatus.pending: 'Pending',
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'Status', fontSize: labelSz),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Wrap(
            spacing: AppLayout.scaleWidth(context, 8),
            runSpacing: AppLayout.scaleHeight(context, 8),
            children: options.map((status) {
              final selected = draft.status == status;
              return GestureDetector(
                onTap: () {
                  ref.read(_filterDraftProvider.notifier).state =
                      draft.copyWith(
                    status: status,
                    clearStatus: status == null,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 18),
                    vertical: AppLayout.scaleHeight(context, 9),
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryTeal
                        : AppColors.backgroundScreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected ? AppColors.primaryTeal : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    labels[status]!,
                    style: TextStyle(
                      fontSize: chipSz,
                      color: selected ? AppColors.white : AppColors.textGrey,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'PolySans',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _BottomBar extends ConsumerWidget {
  final FilterDraft draft;
  final bool isTablet;

  const _BottomBar({required this.draft, required this.isTablet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppLayout.scaleWidth(context, isTablet ? 24 : 16);
    final vPad = AppLayout.scaleHeight(context, 16);
    final btnH = AppLayout.scaleHeight(context, 52);
    final fontSz = AppLayout.fontSize(context, isTablet ? 16 : 15);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + bottomInset),
      child: Row(
        children: [
          // Clear All
          Expanded(
            child: SizedBox(
              height: btnH,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(_filterDraftProvider.notifier).state =
                      FilterDraft.cleared;

                  ref.read(transactionFilterProvider.notifier).state =
                      TransactionFilter();
                },
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.primaryTeal, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: fontSz,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'PolySans',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),

          // Apply Filter
          Expanded(
            child: SizedBox(
              height: btnH,
              child: ElevatedButton(
                onPressed:
                    draft.applyEnabled ? () => _apply(context, ref) : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor:
                      AppColors.primaryTeal.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontSize: fontSz,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'PolySans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (draft.dateRange) {
      case DateRangeOption.last7Days:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case DateRangeOption.last30Days:
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case DateRangeOption.last3Months:
        start = DateTime(now.year, now.month - 3, now.day);
        end = now;
        break;
      case DateRangeOption.custom:
        start = draft.customStart;
        end = draft.customEnd;
        break;
    }

    // Write the global filter.
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      status: draft.status,
      startDate: start,
      endDate: end,
    );

    // Reload so the list reflects the new filter.
    ref.read(transactionProvider.notifier).loadTransactions(refresh: true);

    Navigator.maybePop(context);
  }
}

// ---------------------------------------------------------------------------
// Small reusables
// ---------------------------------------------------------------------------

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

class _SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  const _SectionLabel({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: AppColors.textGrey,
        fontWeight: FontWeight.w400,
        fontFamily: 'PolySans',
      ),
    );
  }
}

// Rounded dropdown matching the card style.
class _AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final double valueFontSize;
  final void Function(T?) onChanged;

  const _AppDropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.valueFontSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundScreen,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 14),
        vertical: AppLayout.scaleHeight(context, 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textDark,
            size: AppLayout.scaleWidth(context, 22),
          ),
          style: TextStyle(
            fontSize: valueFontSize,
            color: AppColors.textDark,
            fontWeight: FontWeight.w400,
            fontFamily: 'PolySans',
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelOf(item),
                    style: TextStyle(
                      fontSize: valueFontSize,
                      color: AppColors.textDark,
                      fontFamily: 'PolySans',
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// Calendar icon date field matching the mockup.
class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final double valueFontSize;
  final DateTime? firstDate;
  final void Function(DateTime) onPicked;

  const _DateField({
    required this.value,
    required this.hint,
    required this.valueFontSize,
    required this.onPicked,
    this.firstDate,
  });

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().substring(2);
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          lastDate: DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryTeal,
                onPrimary: AppColors.white,
                onSurface: AppColors.textDark,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: AppLayout.scaleHeight(context, 48),
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 14),
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundScreen,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : hint,
                style: TextStyle(
                  fontSize: valueFontSize,
                  color:
                      value != null ? AppColors.textDark : AppColors.textLight,
                  fontFamily: 'PolySans',
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: AppLayout.scaleWidth(context, 18),
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}
