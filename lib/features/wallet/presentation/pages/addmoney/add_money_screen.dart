import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/features/wallet/presentation/pages/addmoney/cash_deposit.dart';
import 'package:kudipay/features/wallet/presentation/pages/addmoney/top_up_with_card.dart';
import 'package:kudipay/features/bankdeposit/presentation/pages/bank_ussd_screen.dart';
import 'package:kudipay/features/qrcode/presentation/pages/qr_code_screen.dart';
import 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  // SVG asset paths
  static const _svgBank = 'assets/icons/bank.svg';
  static const _svgCardholder = 'assets/icons/cardholder.svg';
  static const _svgMoney = 'assets/icons/money.svg';
  static const _svgShare = 'assets/icons/share.svg';
  static const _svgPhone = 'assets/icons/phone.svg';
  static const _svgQr = 'assets/icons/qr.svg';
  static const _svgArrowBack = 'assets/icons/arrow_back.svg';
  static const _svgArrowForward = 'assets/icons/arrow_forward.svg';
  static const _svgError = 'assets/icons/error.svg';
  static const _svgRefresh = 'assets/icons/refresh.svg';
  static const _svgCopy = 'assets/icons/copy.svg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addMoneyOptionsProvider.notifier).loadOptions();
      ref.read(accountDetailsProvider.notifier).loadAccountDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionsState = ref.watch(addMoneyOptionsProvider);
    final accountDetailsState = ref.watch(accountDetailsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, optionsState, accountDetailsState),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          _svgArrowBack,
          width: AppLayout.scaleWidth(context, 20),
          height: AppLayout.scaleWidth(context, 20),
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add Money',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    AddMoneyOptionsState optionsState,
    AccountDetailsState accountDetailsState,
  ) {
    if (optionsState.isLoading && optionsState.options.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (optionsState.error != null && optionsState.options.isEmpty) {
      return _buildErrorView(context, optionsState.error!);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
      color: AppColors.primaryTeal,
      backgroundColor: Colors.white,
      strokeWidth: 1.5,
      displacement: 60,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppLayout.pagePadding(context),
        child: Column(
          children: [
            if (optionsState.options.isNotEmpty)
              _buildBankTransferCard(context, accountDetailsState),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildOrDivider(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            ...optionsState.options
                .where((option) => option.type != AddMoneyType.bankTransfer)
                .map(
                  (option) => Padding(
                    padding: EdgeInsets.only(
                      bottom: AppLayout.scaleHeight(context, 12),
                    ),
                    child: _buildAddMoneyOption(context, option),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── Bank Transfer Card ────────────────────────────────────────────────────

  Widget _buildBankTransferCard(
    BuildContext context,
    AccountDetailsState accountDetailsState,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _handleBankTransferTap(context, accountDetailsState),
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 8),
              ),
              child: Row(
                children: [
                  _buildIconContainer(context, assetPath: _svgBank),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Transfer',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 4)),
                        Text(
                          'Add money via mobile or internet banking',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 10),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    _svgArrowForward,
                    width: AppLayout.scaleWidth(context, 16),
                    height: AppLayout.scaleWidth(context, 16),
                    colorFilter: ColorFilter.mode(
                      Colors.grey[400]!,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (accountDetailsState.accountDetails != null) ...[
            Divider(
              height: AppLayout.scaleHeight(context, 24),
              color: Colors.grey[200],
            ),
            _buildAccountDetailsSection(
              context,
              accountDetailsState.accountDetails!,
            ),
          ],
          if (accountDetailsState.isLoading)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primaryTeal,
                strokeWidth: 1,
              ),
            ),
          if (accountDetailsState.error != null)
            Padding(
              padding: EdgeInsets.only(
                top: AppLayout.scaleHeight(context, 12),
              ),
              child: Text(
                accountDetailsState.error!,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: AppLayout.fontSize(context, 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Account Details Section ───────────────────────────────────────────────

  Widget _buildAccountDetailsSection(
    BuildContext context,
    AccountDetails accountDetails,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kudiklit Account Number',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              accountDetails.accountNumber,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 2,
              ),
            ),
            InkWell(
              onTap: () =>
                  _copyToClipboard(context, accountDetails.accountNumber),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
              child: Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 8)),
                child: SvgPicture.asset(
                  _svgShare,
                  width: AppLayout.scaleWidth(context, 20),
                  height: AppLayout.scaleWidth(context, 20),
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryTeal,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── OR Divider ────────────────────────────────────────────────────────────

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
          ),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }

  // ── Option Card ───────────────────────────────────────────────────────────

  Widget _buildAddMoneyOption(BuildContext context, AddMoneyOption option) {
    final String assetPath;
    switch (option.icon) {
      case 'cash':
        assetPath = _svgMoney;
        break;
      case 'card':
        assetPath = _svgCardholder;
        break;
      case 'phone':
        assetPath = _svgPhone;
        break;
      case 'qr':
        assetPath = _svgQr;
        break;
      default:
        assetPath = _svgBank;
    }

    return InkWell(
      onTap: () => _handleOptionTap(context, option),
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconContainer(context, assetPath: assetPath),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              _svgArrowForward,
              width: AppLayout.scaleWidth(context, 16),
              height: AppLayout.scaleWidth(context, 16),
              colorFilter: ColorFilter.mode(
                Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared icon container ─────────────────────────────────────────────────

  /// Teal-tinted rounded square housing an SVG icon — reused across every card.
  Widget _buildIconContainer(
    BuildContext context, {
    required String assetPath,
  }) {
    return Container(
      width: AppLayout.scaleWidth(context, 40),
      height: AppLayout.scaleWidth(context, 40),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: AppLayout.scaleWidth(context, 15),
          height: AppLayout.scaleWidth(context, 15),
          colorFilter: const ColorFilter.mode(
            AppColors.primaryTeal,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // ── Error View ────────────────────────────────────────────────────────────

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              _svgError,
              width: AppLayout.scaleWidth(context, 64),
              height: AppLayout.scaleWidth(context, 64),
              colorFilter: ColorFilter.mode(
                Colors.red[300]!,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            ...[
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(addMoneyOptionsProvider.notifier).loadOptions();
                  ref
                      .read(accountDetailsProvider.notifier)
                      .loadAccountDetails();
                },
                icon: SvgPicture.asset(
                  _svgRefresh,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 32),
                    vertical: AppLayout.scaleHeight(context, 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Navigation handlers ───────────────────────────────────────────────────

  void _handleBankTransferTap(
    BuildContext context,
    AccountDetailsState accountDetailsState,
  ) {
    if (accountDetailsState.accountDetails != null) {
      _showAccountDetailsBottomSheet(
        context,
        accountDetailsState.accountDetails!,
      );
    }
  }

  void _handleOptionTap(BuildContext context, AddMoneyOption option) {
    ref.read(selectedAddMoneyOptionProvider.notifier).state = option;

    switch (option.type) {
      case AddMoneyType.cashDeposit:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CashDepositInstructionsScreen(),
          ),
        );
        break;
      case AddMoneyType.cardTopUp:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardTopUpFormScreen()),
        );
        break;
      case AddMoneyType.ussdTransfer:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BankUssdScreen()),
        );
        break;
      case AddMoneyType.qrCode:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrCodeScreen()),
        );
        break;
      default:
        break;
    }
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _showAccountDetailsBottomSheet(
    BuildContext context,
    AccountDetails accountDetails,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.scaleWidth(context, 24)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: AppLayout.scaleHeight(context, 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Text(
              'Bank Transfer Details',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            _buildDetailRow(context, 'Bank Name', accountDetails.bankName),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildDetailRow(
                context, 'Account Name', accountDetails.accountName),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildDetailRow(
              context,
              'Account Number',
              accountDetails.accountNumber,
              isCopyable: true,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                minimumSize: Size(
                  double.infinity,
                  AppLayout.scaleHeight(context, 50),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppLayout.scaleWidth(context, 12),
                  ),
                ),
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isCopyable) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              InkWell(
                onTap: () => _copyToClipboard(context, value),
                child: SvgPicture.asset(
                  _svgCopy,
                  width: AppLayout.scaleWidth(context, 16),
                  height: AppLayout.scaleWidth(context, 16),
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryTeal,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Clipboard helper ──────────────────────────────────────────────────────

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }
}
