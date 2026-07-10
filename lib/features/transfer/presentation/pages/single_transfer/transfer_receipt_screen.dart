import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/shared/widgets/contact_picker_bottom_sheet.dart';
import 'package:kudipay/features/qrcode/presentation/pages/qr_code_screen.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transfer_amount_screen.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/bank_selection_bottom_sheet.dart';

class TransferRecipientScreen extends ConsumerStatefulWidget {
  const TransferRecipientScreen({super.key});

  @override
  ConsumerState<TransferRecipientScreen> createState() =>
      _TransferRecipientScreenState();
}

class _TransferRecipientScreenState
    extends ConsumerState<TransferRecipientScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late TabController _tabController;
  Bank? _selectedBank;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        ref
            .read(p2pTransferProvider.notifier)
            .setTransferType(TransferType.kudikit);
      } else {
        ref
            .read(p2pTransferProvider.notifier)
            .setTransferType(TransferType.otherBank);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _accountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // -- Contact Picker ---------------------------------------------------------
  Future<void> _pickFromContacts() async {
    FocusScope.of(context).unfocus();

    final selected = await showContactPicker(context);

    if (selected == null || !mounted) return;

    _phoneController.text = selected.displayNumber;

    ref
        .read(p2pTransferProvider.notifier)
        .validateAccount(selected.normalizedNumber);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Info banner
          _buildInfoBanner(context),

          // Tab bar
          _buildTabBar(context),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKudikitTab(context, state),
                _buildOtherBankTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transfer Money',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      decoration: BoxDecoration(
          color: const Color(0xFFD5F2ED),
          borderRadius: BorderRadius.circular(10)),
      child: Text(
        'Free Transfer to Kudikit accounts',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 13),
          color: const Color(0xFF339992),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: Color(0xFF339992),
          ),
        ),
        labelColor: AppColors.primaryTeal,
        unselectedLabelColor: Colors.black54,
        labelStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'To Kudikit'),
          Tab(text: 'To Other Bank'),
        ],
      ),
    );
  }

  Widget _buildKudikitTab(BuildContext context, P2PTransferState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Input card
            _buildInputCard(context, state),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Recent contacts
            _buildRecentContacts(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherBankTab(BuildContext context, P2PTransferState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Input card for Other Bank
            _buildOtherBankInputCard(context, state),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Recent contacts
            _buildRecentContacts(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherBankInputCard(
      BuildContext context, P2PTransferState state) {
    final hasRecipient = state.transferData.recipient != null;
    final hasError = state.error != null;

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account number input
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit Account No. or Phone No.',
              hintStyle: TextStyle(
                color: Colors.black38,
                fontSize: AppLayout.fontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : hasRecipient
                          ? AppColors.primaryTeal
                          : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : hasRecipient
                          ? AppColors.primaryTeal
                          : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryTeal,
                  width: 0.5,
                ),
              ),
              suffixIcon: hasRecipient
                  ? SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: AppLayout.scaleWidth(context, 10),
                      height: AppLayout.scaleWidth(context, 10),
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryTeal,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
              counterText: '',
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 12)),

          // Bank selector
          InkWell(
            onTap: _accountController.text.length == 10
                ? () {
                    BankSelectionBottomSheet.show(
                      context,
                      onBankSelected: (bank) {
                        setState(() {
                          _selectedBank = bank;
                        });
                        ref.read(p2pTransferProvider.notifier).validateAccount(
                              _accountController.text,
                            );
                      },
                    );
                  }
                : null,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 16),
                vertical: AppLayout.scaleHeight(context, 14),
              ),
              decoration: BoxDecoration(
                border: Border.all(
                    color: _selectedBank != null
                        ? AppColors.primaryTeal
                        : Colors.grey[300]!,
                    width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_selectedBank != null) ...[
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFF6B35),
                      radius: AppLayout.scaleWidth(context, 16),
                      child: Text(
                        _selectedBank!.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: Text(
                        _selectedBank!.name,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        'Select Bank',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    size: AppLayout.scaleWidth(context, 16),
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),

          // Recipient info (shown after validation)
          if (hasRecipient) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 12),
                vertical: AppLayout.scaleHeight(context, 8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/check.svg',
                    width: AppLayout.scaleWidth(context, 12),
                    height: AppLayout.scaleWidth(context, 12),
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryTeal,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 8)),
                  Text(
                    state.transferData.recipient!.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 48),
            child: ElevatedButton(
              onPressed: hasRecipient && !state.isValidatingAccount
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransferAmountScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFB2DFDB),
              ),
              child: state.isValidatingAccount
                  ? SizedBox(
                      width: AppLayout.scaleWidth(context, 20),
                      height: AppLayout.scaleWidth(context, 20),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
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
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, P2PTransferState state) {
    final hasRecipient = state.transferData.recipient != null;
    final hasError = state.error != null;

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account number input
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit Account No. or Phone No.',
              hintStyle: TextStyle(
                color: Colors.black38,
                fontSize: AppLayout.fontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : hasRecipient
                          ? AppColors.primaryTeal
                          : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : hasRecipient
                          ? AppColors.primaryTeal
                          : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryTeal,
                  width: 2,
                ),
              ),
              suffixIcon: hasRecipient
                  ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                  : null,
              counterText: '',
            ),
            onChanged: (value) {
              if (value.length == 10) {
                ref.read(p2pTransferProvider.notifier).validateAccount(value);
              }
            },
          ),

          // Error message
          if (hasError) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 12),
                vertical: AppLayout.scaleHeight(context, 8),
              ),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[700],
                    size: AppLayout.scaleWidth(context, 16),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 8)),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Recipient info
          if (hasRecipient) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 12),
                vertical: AppLayout.scaleHeight(context, 8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primaryTeal,
                    size: AppLayout.scaleWidth(context, 16),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 8)),
                  Text(
                    state.transferData.recipient!.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: 'QR Code',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QrCodeScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.contacts_outlined,
                  label: 'Contacts',
                  onTap: _pickFromContacts,
                ),
              ),
            ],
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: hasRecipient && !state.isValidatingAccount
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransferAmountScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFB2DFDB),
              ),
              child: state.isValidatingAccount
                  ? SizedBox(
                      width: AppLayout.scaleWidth(context, 20),
                      height: AppLayout.scaleWidth(context, 20),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
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
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 18),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 8)),
            Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContacts(BuildContext context, P2PTransferState state) {
    if (state.recentContacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Row(
            children: [
              _buildContactTab(context, 'Recent', true),
              SizedBox(width: AppLayout.scaleWidth(context, 24)),
              _buildContactTab(context, 'Favourite', false),
              SizedBox(width: AppLayout.scaleWidth(context, 24)),
              _buildContactTab(context, 'Kudikit Contact', false),
            ],
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Contact list
          ...state.recentContacts
              .map((contact) => _buildContactItem(context, contact)),
        ],
      ),
    );
  }

  Widget _buildContactTab(BuildContext context, String label, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: isActive ? AppColors.primaryTeal : Colors.black54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 4)),
        if (isActive)
          Container(
            width: AppLayout.scaleWidth(context, 40),
            height: 2,
            color: AppColors.primaryTeal,
          ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, RecentContact contact) {
    return InkWell(
      onTap: () {
        _accountController.text = contact.accountNumber;
        ref.read(p2pTransferProvider.notifier).selectRecipient(
              RecipientInfo(
                accountNumber: contact.accountNumber,
                name: contact.name,
                bank: contact.bank,
              ),
            );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 12),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: AppLayout.scaleWidth(context, 20),
              backgroundColor: contact.name.contains('Squad')
                  ? Colors.orange
                  : Colors.blue[900],
              child: Text(
                contact.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(width: AppLayout.scaleWidth(context, 12)),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text(
                    '${contact.accountNumber} • ${contact.bank}',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text(
                    _formatDate(contact.lastTransferDate),
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 11),
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 30) {
      return 'Jan $difference, 2024';
    }
    return 'Jan ${difference ~/ 30}, 2024';
  }
}
