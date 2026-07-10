// ============================================================================
// lib/presentation/bills/airtime/airtime_amount_screen.dart
//
// Screen 2 of the Buy Airtime flow.
//
// Features:
//   • Promo banner: "Buy ?1,000 + Get ?100 Bonus"
//   • Network + phone display row (tap network to go back and change)
//   • Amount input: ? prefix, range hint ?60 – ?50,000
//   • Balance display (from wallet provider)
//   • 6-preset quick-select grid: ?100, ?200, ?500, ?1,000, ?5,000, ?6,000
//   • Continue enabled only when amount is valid
//   • ConfirmAirtimeBottomSheet: review + "Recheck" / "Send"
//   • AirtimeSuccessBottomSheet: check icon + amount + "Add to beneficiary"
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/shared/widgets/network_logo.dart';
import 'package:kudipay/features/bills/domain/entities/bill_model.dart';
import 'package:kudipay/features/bills/presentation/pages/bill_transaction_detail.dart';
import 'package:kudipay/features/bills/presentation/controllers/bills_controllers.dart';
import 'package:kudipay/features/kyc/presentation/controllers/kyc_controllers.dart';
import 'package:kudipay/features/wallet/presentation/controllers/wallet_provider.dart';

class AirtimeAmountScreen extends ConsumerStatefulWidget {
  const AirtimeAmountScreen({super.key});

  @override
  ConsumerState<AirtimeAmountScreen> createState() =>
      _AirtimeAmountScreenState();
}

class _AirtimeAmountScreenState extends ConsumerState<AirtimeAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final _fmt = NumberFormat('#,###', 'en_NG');

  // Preset amounts matching design
  static const List<double> _presets = [100, 200, 500, 1000, 5000, 6000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountTyped);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountTyped);
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountTyped() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(raw);
    ref.read(airtimeProvider.notifier).setAmount(parsed ?? 0.0);
  }

  void _selectPreset(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    ref.read(airtimeProvider.notifier).setAmount(amount);
    FocusScope.of(context).unfocus();
  }

  void _onContinue() {
    FocusScope.of(context).unfocus();
    _showConfirmSheet();
  }

  void _showConfirmSheet() {
    final state = ref.read(airtimeProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmAirtimeBottomSheet(
        phoneNumber: state.phoneNumber,
        network: state.selectedNetwork!,
        amount: state.amount!,
        onSend: () {
          Navigator.pop(context); // close confirm
          ref.read(airtimeProvider.notifier).processAirtime().then((_) {
            if (mounted) _showSuccessOrError();
          });
        },
      ),
    );
  }

  void _showSuccessOrError() {
    final state = ref.read(airtimeProvider);
    if (state.step == AirtimeStep.success) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (_) => AirtimeSuccessBottomSheet(
          amount: state.amount!,
          onDone: () {
            // Pop success sheet ? pop amount screen ? pop phone screen ? home
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onDetails: () {
            Navigator.pop(context); // close success sheet
            final s = ref.read(airtimeProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillTransactionDetail(
                  title: 'Airtime Receipt',
                  transactionId: s.result?.transactionId ??
                      'TXN${DateTime.now().millisecondsSinceEpoch}',
                  billType: 'Airtime',
                  providerName: s.selectedNetwork?.displayName ?? '',
                  amount: s.amount ?? 0,
                  transactionDate: s.result?.createdAt ?? DateTime.now(),
                  recipientNumber: s.phoneNumber,
                  recipientName: '',
                  extraDetails: {
                    'Network': s.selectedNetwork?.displayName ?? '',
                  },
                ),
              ),
            );
          },
        ),
      );
    } else if (state.step == AirtimeStep.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Transaction failed. Please try again.'),
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
    final state = ref.watch(airtimeProvider);
    final wallet = ref.watch(walletProvider);
    final isProcessing = state.step == AirtimeStep.processing;

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
                    'Buy Airtime',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),

                    // -- Promo banner -------------------------------------
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 10),
                        horizontal: AppLayout.scaleWidth(context, 16),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Buy ?1,000 + Get ?100 Bonus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF069494),
                        ),
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Network + phone display --------------------------
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
                          // SIM icon badge
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sim_card_outlined,
                              color: Color(0xFF069494),
                              size: 22,
                            ),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Network label + changeable network name
                              Row(
                                children: [
                                  Text(
                                    'Network  ',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                  if (state.selectedNetwork != null)
                                    GestureDetector(
                                      // Tap to go back and change network
                                      onTap: () => Navigator.pop(context),
                                      child: Row(
                                        children: [
                                          Text(
                                            state.selectedNetwork!.displayName,
                                            style: TextStyle(
                                              fontSize: AppLayout.fontSize(
                                                  context, 12),
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF069494),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Color(0xFF069494),
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

                    SizedBox(height: AppLayout.scaleHeight(context, 16)),

                    // -- Amount input card --------------------------------
                    Container(
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Airtime Amount',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),

                          // ? + text field
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '?',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 22),
                                  fontWeight: FontWeight.w600,
                                  color:
                                      state.amount != null && state.amount! > 0
                                          ? const Color(0xFF1A1A2E)
                                          : const Color(0xFFBDBDBD),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  focusNode: _amountFocus,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 22),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '60.00 - 50,000.00',
                                    hintStyle: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 15),
                                      color: const Color(0xFFBDBDBD),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 8)),

                          // Balance
                          Text(
                            'Balance: ?${wallet.formattedBalance}',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),

                          SizedBox(height: AppLayout.scaleHeight(context, 14)),

                          // Preset amount grid (3 × 2)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _presets.length,
                            itemBuilder: (_, i) {
                              final preset = _presets[i];
                              final isSelected = state.amount == preset;
                              return GestureDetector(
                                onTap: () => _selectPreset(preset),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF069494)
                                        : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF069494)
                                          : const Color(0xFFE8E8E8),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '?${_fmt.format(preset)}',
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 13),
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ),
                                ),
                              );
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
                height: AppLayout.scaleHeight(context, 54),
                child: ElevatedButton(
                  onPressed: state.canProceedFromAmount && !isProcessing
                      ? _onContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    disabledBackgroundColor:
                        const Color(0xFF069494).withValues(alpha: 0.35),
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
    final digits = phone.replaceAll(' ', '');
    if (digits.length == 11) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return phone;
  }
}

// ============================================================================
// ConfirmAirtimeBottomSheet
// Review screen shown before the transaction is sent.
// ===========================================================================

class ConfirmAirtimeBottomSheet extends ConsumerWidget {
  final String phoneNumber;
  final NetworkProvider network;
  final double amount;
  final VoidCallback onSend;

  const ConfirmAirtimeBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.network,
    required this.amount,
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

              // "For airtime" + close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'For airtime',
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

              // Amount display
              Text(
                '?${fmt.format(amount)}',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 36),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF069494),
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
                    _DetailRow(label: 'To', value: _fmt11(phoneNumber)),
                    const Divider(height: 20, color: Color(0xFFEEEEEE)),
                    _DetailRow(
                      label: 'Network',
                      value: network.displayName,
                      trailing: NetworkLogo(network: network, size: 22),
                    ),
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
                            color: Color(0xFF069494), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
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
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        backgroundColor: const Color(0xFF069494),
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

// ============================================================================
// AirtimeSuccessBottomSheet
// Shown after a successful airtime transaction.
// ============================================================================

class AirtimeSuccessBottomSheet extends StatefulWidget {
  final double amount;
  final VoidCallback onDone;
  final VoidCallback onDetails;

  const AirtimeSuccessBottomSheet({
    super.key,
    required this.amount,
    required this.onDone,
    required this.onDetails,
  });

  @override
  State<AirtimeSuccessBottomSheet> createState() =>
      _AirtimeSuccessBottomSheetState();
}

class _AirtimeSuccessBottomSheetState extends State<AirtimeSuccessBottomSheet> {
  bool _addToBeneficiary = true;
  final TextEditingController _nameController = TextEditingController();
  final _fmt = NumberFormat('#,###', 'en_NG');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Green check + amount
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF069494),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    '-?${_fmt.format(widget.amount)}',
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
                'Airtime request successfully submitted',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // Add to beneficiary card
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
                          activeThumbColor: const Color(0xFF069494),
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
                                const BorderSide(color: Color(0xFF069494)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Details + Done buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDetails,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14)),
                        side: const BorderSide(
                            color: Color(0xFF069494), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF069494),
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
                        backgroundColor: const Color(0xFF069494),
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

// -- Shared bottom sheet row -------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const _DetailRow({required this.label, required this.value, this.trailing});

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
    // Pull live wallet data — account number and initials from the mock API,
    // not hardcoded literals.
    final wallet = ref.watch(walletProvider);
    final initials = wallet.initials;
    final acctNum = wallet.accountNumber;
    final balance = wallet.formattedBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paying from',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: const Color(0xFF9E9E9E),
          ),
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
                    initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName  $acctNum',
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
                      '? $balance',
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
