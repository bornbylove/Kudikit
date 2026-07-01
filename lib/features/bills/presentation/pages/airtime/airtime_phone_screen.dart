import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/contact_picker_bottom_sheet.dart';

import 'package:kudipay/shared/widgets/network_logo.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/features/bills/presentation/pages/airtime/airtime_amount_screen.dart';
import 'package:kudipay/provider/bill/bill_provider.dart';

import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';

// ============================================================================
// AirtimePhoneScreen
// Screen 1 of the Buy Airtime flow.
//
// Changes from previous version:
//   • _pickFromContacts() now opens the real ContactPickerBottomSheet
//   • Selected contact auto-fills phone input + triggers network detection
//   • "Contact" tab now opens the real picker instead of showing empty state
// ============================================================================

class AirtimePhoneScreen extends ConsumerStatefulWidget {
  const AirtimePhoneScreen({super.key});

  @override
  ConsumerState<AirtimePhoneScreen> createState() => _AirtimePhoneScreenState();
}

class _AirtimePhoneScreenState extends ConsumerState<AirtimePhoneScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(airtimeProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    ref.read(airtimeProvider.notifier).setPhoneNumber(value);
  }

  // -- Contact Picker ---------------------------------------------------------
  // Opens the Nigerian-filtered contact picker bottom sheet.
  // When the user selects a number, we:
  //   1. Format it for display (0803 456 0109)
  //   2. Fill the text field
  //   3. Run network auto-detection via the provider
  Future<void> _pickFromContacts() async {
    // Close keyboard before opening the sheet
    FocusScope.of(context).unfocus();

    final selected = await showContactPicker(context);

    if (selected == null || !mounted) return;

    // Fill the phone field with the formatted display number
    _phoneController.text = selected.displayNumber;

    // Tell the provider about the raw normalized number (0XXXXXXXXXX)
    // Network is already detected — we pass it directly to skip re-detection
    final network = selected.network;
    if (network != null) {
      ref.read(airtimeProvider.notifier).setPhoneNumberWithNetwork(
            selected.normalizedNumber, network);
    } else {
      ref.read(airtimeProvider.notifier).setPhoneNumber(selected.normalizedNumber);
    }
  }

  void _buyForSelf() {
    final wallet = ref.read(walletProvider);
    // Use wallet account number as the self-purchase number; fall back to
    // a known default if the wallet hasn't loaded yet.
    final selfPhone = wallet.accountNumber.isNotEmpty
        ? wallet.accountNumber
        : '08104532643';
    _phoneController.text = _formatPhoneDisplay(selfPhone);
    ref.read(airtimeProvider.notifier).setPhoneNumber(selfPhone);
  }

  String _formatPhoneDisplay(String phone) {
    final digits = phone.replaceAll(' ', '');
    if (digits.length == 11) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  void _selectBeneficiary(BillsBeneficiary b) {
    _phoneController.text = _formatPhoneDisplay(b.phoneNumber);
    ref.read(airtimeProvider.notifier).setPhoneNumber(b.phoneNumber);
  }

  void _proceed() {
    ref.read(airtimeProvider.notifier).closeNetworkDropdown();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AirtimeAmountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(airtimeProvider);
    final beneficiariesState = ref.watch(beneficiariesProvider);
    final isInputEmpty = _phoneController.text.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar ----------------------------------------------------
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
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  ref.read(airtimeProvider.notifier).closeNetworkDropdown();
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),

                      // -- Phone Number Input Card ------------------------
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                              'Enter phone number',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 13),
                                color: const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: AppLayout.scaleHeight(context, 6)),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    onChanged: _onPhoneChanged,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                      _PhoneNumberFormatter(),
                                    ],
                                    style: TextStyle(
                                      fontSize:
                                          AppLayout.fontSize(context, 17),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0803 000 0000',
                                      hintStyle: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 17),
                                        color: const Color(0xFFBDBDBD),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                // -- Contact picker icon button ---------
                                GestureDetector(
                                  onTap: _pickFromContacts,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5EE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_search_outlined,
                                      color: Color(0xFF069494),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Buy for self shortcut
                            if (isInputEmpty) ...[
                              SizedBox(
                                  height: AppLayout.scaleHeight(context, 10)),
                              const Divider(
                                  height: 1, color: Color(0xFFF0F0F0)),
                              SizedBox(
                                  height: AppLayout.scaleHeight(context, 10)),
                              GestureDetector(
                                onTap: _buyForSelf,
                                child: Row(
                                  children: [
                                    Text(
                                      'Buy For Self',
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 13),
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF069494),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF069494),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '08124608695',
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 13),
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.chevron_right,
                                        size: 18, color: Color(0xFF9E9E9E)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 12)),

                      // -- Network Selector ------------------------------
                      if (!isInputEmpty) ...[
                        NetworkDropdown(
                          selectedNetwork: state.selectedNetwork,
                          isOpen: state.isNetworkDropdownOpen,
                          onToggle: () => ref
                              .read(airtimeProvider.notifier)
                              .toggleNetworkDropdown(),
                          onSelect: (network) => ref
                              .read(airtimeProvider.notifier)
                              .setNetwork(network),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 24)),
                      ],

                      // -- Beneficiary Section ----------------------------
                      if (isInputEmpty) ...[
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        Text(
                          'Select Beneficiary',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 12)),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                labelColor: const Color(0xFF069494),
                                unselectedLabelColor: const Color(0xFF9E9E9E),
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                                unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 14),
                                indicatorColor: const Color(0xFF069494),
                                indicatorSize: TabBarIndicatorSize.label,
                                tabs: const [
                                  Tab(text: 'Recent'),
                                  Tab(text: 'Contact'),
                                ],
                              ),
                              SizedBox(
                                height: 200,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // -- Recent tab ----------------------
                                    beneficiariesState.isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF069494),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : beneficiariesState
                                                .beneficiaries.isEmpty
                                            ? const _EmptyBeneficiaries(
                                                message:
                                                    "You haven't purchased any airtime",
                                                subMessage:
                                                    "Start a transaction and we'll show your most recent transaction",
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                itemCount: beneficiariesState
                                                    .beneficiaries.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 12),
                                                itemBuilder: (_, i) {
                                                  final b = beneficiariesState
                                                      .beneficiaries[i];
                                                  return _BeneficiaryTile(
                                                    beneficiary: b,
                                                    onTap: () =>
                                                        _selectBeneficiary(b),
                                                  );
                                                },
                                              ),

                                    // -- Contact tab ---------------------
                                    // Tapping "Contact" tab opens the picker
                                    // directly rather than showing an empty list
                                    _ContactTabPrompt(
                                      onTap: _pickFromContacts,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // -- Continue Button --------------------------------------------
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
                  onPressed: state.canProceedFromPhone ? _proceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    disabledBackgroundColor: const Color(0xFF069494).withValues(alpha: 0.35),
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
}

// ============================================================================
// _ContactTabPrompt
// Shown in the "Contact" tab. A single tappable row that opens the picker.
// Better UX than an empty state — makes it clear what the tab does.
// ============================================================================

class _ContactTabPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _ContactTabPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.contacts_outlined,
                color: Color(0xFF069494),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Browse contacts',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF069494),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to open your Nigerian contacts',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
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
// Shared sub-widgets (unchanged from previous version)
// ============================================================================

class _EmptyBeneficiaries extends StatelessWidget {
  final String message;
  final String subMessage;

  const _EmptyBeneficiaries({
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeneficiaryTile extends StatelessWidget {
  final BillsBeneficiary beneficiary;
  final VoidCallback onTap;

  const _BeneficiaryTile({
    required this.beneficiary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          NetworkLogo(network: beneficiary.network, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficiary.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  beneficiary.phoneNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}