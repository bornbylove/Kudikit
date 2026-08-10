import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/features/bankdeposit/presentation/pages/select_bank.dart';
import 'package:kudipay/features/bankdeposit/presentation/pages/ussd_code_display_screen.dart';
import 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart';

class BankUssdScreen extends ConsumerStatefulWidget {
  const BankUssdScreen({super.key});

  @override
  ConsumerState<BankUssdScreen> createState() => _BankUssdScreenState();
}

class _BankUssdScreenState extends ConsumerState<BankUssdScreen> {
  final TextEditingController _amountController = TextEditingController();
  Bank? _selectedBank;
  bool _isFormValid = false;

  static const List<double> _quickAmounts = [200, 1000, 2000, 3000, 5000, 9999];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateForm);
    _amountController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final isValid = _selectedBank != null &&
        amount != null &&
        amount >= 100 &&
        amount <= 9999;
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
  }

  void _onQuickAmountTapped(double amount) {
    _amountController.text = amount.toInt().toString();
    _validateForm();
  }

  Future<void> _navigateToBankSelection() async {
    final result = await Navigator.push<Bank>(
      context,
      MaterialPageRoute(builder: (_) => const SelectBankScreen()),
    );
    if (result != null) {
      setState(() => _selectedBank = result);
      _validateForm();
    }
  }

  Future<void> _handleConfirm() async {
    if (!_isFormValid) return;
    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    await ref.read(ussdTransferProvider.notifier).generateUssdCode(
          bankCode: _selectedBank!.code,
          amount: amount,
        );

    if (!mounted) return;
    final state = ref.read(ussdTransferProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: AppLayout.scaleHeight(context, 16),
            left: AppLayout.scaleWidth(context, 16),
            right: AppLayout.scaleWidth(context, 16),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UssdCodeDisplayScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ussdState = ref.watch(ussdTransferProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildConfirmButton(context, ussdState.isLoading),
      body: Stack(
        children: [
          _buildBody(context),
          // Fix 2: replace raw CircularProgressIndicator overlay
          if (ussdState.isLoading)
            Container(
              color: Colors.black26,
              child: AppLoadingIndicator.fullPage(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Bank USSD',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 20),
        vertical: AppLayout.scaleHeight(context, 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Fund Method --------------------------------------------------
          _buildSectionLabel(context, 'Fund Method'),
          SizedBox(height: AppLayout.scaleHeight(context, 10)),
          _buildBankSelector(context),

          SizedBox(height: AppLayout.scaleHeight(context, 28)),

          // -- Amount -------------------------------------------------------
          _buildSectionLabel(context, 'Enter or select amount'),
          SizedBox(height: AppLayout.scaleHeight(context, 10)),
          _buildAmountField(context),
          SizedBox(height: AppLayout.scaleHeight(context, 2)),
          _buildQuickAmounts(context),

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // -- Note ---------------------------------------------------------
          _buildTransferNote(context),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      ),
    );
  }

  // -- Bank selector card ----------------------------------------------------
  Widget _buildBankSelector(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToBankSelection,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        decoration: BoxDecoration(
          color:
              _selectedBank == null ? const Color(0xFFF2F2F2) : AppColors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: _selectedBank == null
            ? Center(
                child: Text(
                  'Select a Bank',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : Row(
                children: [
                  _BankLogoCircle(
                    bank: _selectedBank!,
                    size: AppLayout.scaleWidth(context, 34),
                    fontSize: AppLayout.fontSize(context, 11),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Text(
                    _selectedBank!.name,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // -- Amount field ----------------------------------------------------------
  Widget _buildAmountField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          top: BorderSide(color: Color(0xFFE8E8E8)),
          left: BorderSide(color: Color(0xFFE8E8E8)),
          right: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 2),
      ),
      child: Row(
        children: [
          Text(
            '?',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 6)),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Enter 100 - 9,999',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppLayout.fontSize(context, 15),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Quick amount chips ----------------------------------------------------
  Widget _buildQuickAmounts(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppLayout.scaleWidth(context, 10)),
          bottomRight: Radius.circular(AppLayout.scaleWidth(context, 10)),
        ),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 10)),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppLayout.scaleWidth(context, 8),
        mainAxisSpacing: AppLayout.scaleHeight(context, 8),
        childAspectRatio: 3.0,
        children: _quickAmounts
            .map((amount) => _buildQuickAmountChip(context, amount))
            .toList(),
      ),
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, double amount) {
    final isSelected = _amountController.text == amount.toInt().toString();

    return GestureDetector(
      onTap: () => _onQuickAmountTapped(amount),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.08)
              : AppColors.backgroundScreen,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 6)),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFE8E8E8),
          ),
        ),
        child: Text(
          '?${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            fontWeight: FontWeight.w400,
            color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // -- Transfer note ---------------------------------------------------------
  Widget _buildTransferNote(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 10),
          color: AppColors.textGrey,
        ),
        children: [
          const TextSpan(text: 'For amount above ?9,999, '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'use bank transfer now',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Confirm button --------------------------------------------------------
  Widget _buildConfirmButton(BuildContext context, bool isLoading) {
    return Container(
      color: AppColors.backgroundScreen,
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 20) +
            MediaQuery.of(context).padding.bottom,
      ),
      child: ElevatedButton(
        onPressed: (_isFormValid && !isLoading) ? _handleConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          disabledBackgroundColor:
              AppColors.primaryTeal.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          minimumSize:
              Size(double.infinity, AppLayout.scaleHeight(context, 52)),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
          ),
          elevation: 0,
        ),
        // Fix 1: show AppLoadingIndicator.button() spinner when loading
        child: isLoading
            ? const AppLoadingIndicator.button()
            : Text(
                'Confirm',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // -- Helpers ---------------------------------------------------------------
  String _formatAmount(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// --- Shared bank logo circle widget ------------------------------------------

class _BankLogoCircle extends StatelessWidget {
  final Bank bank;
  final double size;
  final double fontSize;

  const _BankLogoCircle({
    required this.bank,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bankColor(bank.logo),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final networkUrl = _bankLogoUrl(bank.logo);
    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsWidget(),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        _initials(bank.name),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _bankLogoUrl(String logo) {
    const Map<String, String> logos = {
      'gtbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/GTBank_logo.svg/200px-GTBank_logo.svg.png',
      'firstbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/First_bank_of_Nigeria_plc_logo.png/200px-First_bank_of_Nigeria_plc_logo.png',
      'wema':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Wema_Bank_Logo.png/200px-Wema_Bank_Logo.png',
      'uba':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/United_Bank_for_Africa_Logo.svg/200px-United_Bank_for_Africa_Logo.svg.png',
      'fcmb':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/FCMB_logo.png/200px-FCMB_logo.png',
      'sterling':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Sterling_Bank_Logo.png/200px-Sterling_Bank_Logo.png',
    };
    return logos[logo.toLowerCase()];
  }

  Color _bankColor(String logo) {
    switch (logo.toLowerCase()) {
      case 'gtbank':
        return const Color(0xFFFF6600);
      case 'firstbank':
        return const Color(0xFF002244);
      case 'wema':
        return const Color(0xFF722C7A);
      case 'uba':
        return const Color(0xFFD32F2F);
      case 'fcmb':
        return const Color(0xFF7B1FA2);
      case 'sterling':
        return const Color(0xFFD32F2F);
      case 'parallex':
        return const Color(0xFF1E3A8A);
      case 'globus':
        return const Color(0xFFD32F2F);
      default:
        return AppColors.primaryTeal;
    }
  }

  String _initials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
