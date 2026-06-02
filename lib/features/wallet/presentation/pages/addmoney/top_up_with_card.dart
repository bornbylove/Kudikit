import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/presentation/otp/otp_verification_screen.dart';
import 'package:kudipay/provider/funding/funding_provider.dart';

class CardTopUpFormScreen extends ConsumerStatefulWidget {
  const CardTopUpFormScreen({super.key});

  @override
  ConsumerState<CardTopUpFormScreen> createState() =>
      _CardTopUpFormScreenState();
}

class _CardTopUpFormScreenState extends ConsumerState<CardTopUpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _pinController = TextEditingController();

  bool _cvvVisible = false;
  bool _pinVisible = false;
  bool _isFormValid = false;

  static const _primaryColor = Color(0xFF069494);

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _cardNumberController.addListener(_validateForm);
    _expiryController.addListener(_validateForm);
    _cvvController.addListener(_validateForm);
    _pinController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateForm);
    _cardNumberController.removeListener(_validateForm);
    _expiryController.removeListener(_validateForm);
    _cvvController.removeListener(_validateForm);
    _pinController.removeListener(_validateForm);

    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ─── Validation ──────────────────────────────────────────────────────────────

  void _validateForm() {
    final amount = double.tryParse(_amountController.text);
    final cardDigits = _cardNumberController.text.replaceAll(' ', '');
    final expiryParts = _expiryController.text.split(' / ');

    final isValid = amount != null &&
        amount > 0 &&
        cardDigits.length >= 13 &&
        cardDigits.length <= 19 &&
        expiryParts.length == 2 &&
        expiryParts[0].length == 2 &&
        expiryParts[1].length == 2 &&
        _cvvController.text.length >= 3 &&
        _pinController.text.length == 4;

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cardTopUpState = ref.watch(cardTopUpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildConfirmButton(context),
      body: Stack(
        children: [
          _buildBody(context),
          if (cardTopUpState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: _primaryColor,strokeWidth: 1,),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Top-up with card or account',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildAmountField(context),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            _buildCardNumberField(context),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Row(
              children: [
                Expanded(child: _buildExpiryField(context)),
                SizedBox(width: AppLayout.scaleWidth(context, 16)),
                Expanded(child: _buildCvvField(context)),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            _buildPinField(context),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
          ],
        ),
      ),
    );
  }

  // ─── Reusable Helpers ────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    String? prefix,
    Widget? suffix,
    double? hintFontSize,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: AppLayout.fontSize(context, hintFontSize ?? 14),
      ),
      prefixText: prefix,
      prefixStyle: TextStyle(
        fontSize: AppLayout.fontSize(context, 16),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: _border(context),
      enabledBorder: _border(context),
      focusedBorder: _border(context, focused: true),
      errorBorder: _border(context, error: true),
      focusedErrorBorder: _border(context, error: true),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
    );
  }

  OutlineInputBorder _border(
    BuildContext context, {
    bool focused = false,
    bool error = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      borderSide: BorderSide(
        color: error
            ? Colors.red
            : focused
                ? Colors.grey
                : Colors.grey[300]!,
        width: focused ? 1 : 0.5,
      ),
    );
  }

  TextStyle _fieldTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: AppLayout.fontSize(context, 16),
      fontWeight: FontWeight.w500,
    );
  }

  Widget _fieldLabel(
    BuildContext context,
    String label, {
    bool showInfo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 8)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (showInfo) ...[
            SizedBox(width: AppLayout.scaleWidth(context, 4)),
            Icon(
              Icons.info_outline,
              size: AppLayout.scaleWidth(context, 16),
              color: Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }

  Widget _visibilityToggle(
    BuildContext context, {
    required bool visible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        color: Colors.grey[400],
        size: AppLayout.scaleWidth(context, 20),
      ),
      onPressed: onTap,
    );
  }

  // ─── Form Fields ─────────────────────────────────────────────────────────────

  Widget _buildAmountField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Amount'),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          style: _fieldTextStyle(context),
          decoration: _fieldDecoration(
            context,
            hint: '100.00',
            hintFontSize: 16,
            prefix: '₦',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter amount';
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) return 'Please enter a valid amount';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCardNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Card Number'),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberInputFormatter(),
          ],
          style: _fieldTextStyle(context),
          decoration: _fieldDecoration(
            context,
            hint: 'Enter 13 - 19 digit card number',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter card number';
            final digits = value.replaceAll(' ', '');
            if (digits.length < 13 || digits.length > 19) {
              return 'Please enter a valid card number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExpiryField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Expiry Date'),
        TextFormField(
          controller: _expiryController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
            _ExpiryDateInputFormatter(),
          ],
          style: _fieldTextStyle(context),
          decoration: _fieldDecoration(context, hint: 'MM / YY'),
          validator: (value) {
            final input = value?.trim();
            if (input == null || input.isEmpty) return 'Required';
            final parts = input.split(' / ');
            if (parts.length < 2 ||
                parts[0].length != 2 ||
                parts[1].length != 2) {
              return 'Invalid date';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCvvField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'CVV', showInfo: true),
        TextFormField(
          controller: _cvvController,
          keyboardType: TextInputType.number,
          obscureText: !_cvvVisible,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: _fieldTextStyle(context),
          decoration: _fieldDecoration(
            context,
            hint: 'Enter CVV',
            suffix: _visibilityToggle(
              context,
              visible: _cvvVisible,
              onTap: () => setState(() => _cvvVisible = !_cvvVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (value.length < 3) return 'Invalid CVV';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPinField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Card PIN', showInfo: true),
        TextFormField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: !_pinVisible,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: _fieldTextStyle(context),
          decoration: _fieldDecoration(
            context,
            hint: 'Enter Card PIN',
            suffix: _visibilityToggle(
              context,
              visible: _pinVisible,
              onTap: () => setState(() => _pinVisible = !_pinVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your PIN';
            if (value.length != 4) return 'PIN must be 4 digits';
            return null;
          },
        ),
      ],
    );
  }

  // ─── Confirm Button ───────────────────────────────────────────────────────────

Widget _buildConfirmButton(BuildContext context) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
      AppLayout.scaleWidth(context, 16),
      AppLayout.scaleHeight(context, 12),
      AppLayout.scaleWidth(context, 16),
      AppLayout.scaleHeight(context, 20) +
          MediaQuery.of(context).padding.bottom,
    ),
    child: ElevatedButton(
      onPressed: _isFormValid ? _handleConfirm : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        disabledBackgroundColor: _primaryColor.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: Size(
          double.infinity,
          AppLayout.scaleHeight(context, 52),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppLayout.scaleWidth(context, 28),
          ),
        ),
        elevation: 0,
      ),
      child: Text(
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

  // ─── Handler ─────────────────────────────────────────────────────────────────

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final parts = _expiryController.text.split(' / ');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = CardTopUpRequest(
      amount: double.parse(_amountController.text),
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      expiryMonth: parts[0],
      expiryYear: parts[1],
      cvv: _cvvController.text,
      pin: _pinController.text,
    );

    await ref.read(cardTopUpProvider.notifier).initiateTopUp(request);

    if (!mounted) return;

    final state = ref.read(cardTopUpProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state.response?.requiresOtp == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OtpVerificationScreen(),
        ),
      );
    }
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) buffer.write(' ');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' / ', '');

    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2 ? text.substring(2) : '';
      final formatted = year.isEmpty ? month : '$month / $year';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}