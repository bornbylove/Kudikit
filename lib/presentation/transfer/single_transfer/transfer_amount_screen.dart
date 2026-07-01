import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/features/transfer/domain/entities/transfer_entities.dart';
import 'package:kudipay/presentation/transfer/single_transfer/confirm_transfer_bottom_sheet.dart';

import 'package:kudipay/presentation/transfer/single_transfer/transfer_success_dialogue.dart';
import 'package:kudipay/provider/provider.dart';

class TransferAmountScreen extends ConsumerStatefulWidget {
  const TransferAmountScreen({super.key});

  @override
  ConsumerState<TransferAmountScreen> createState() =>
      _TransferAmountScreenState();
}

class _TransferAmountScreenState extends ConsumerState<TransferAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  TransactionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() {
      if (!_amountFocus.hasFocus && _amountController.text.isNotEmpty) {
        _updateAmount();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (text.isNotEmpty) {
      final amount = double.tryParse(text) ?? 0;
      ref.read(p2pTransferProvider.notifier).setAmount(amount);
    }
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    _updateAmount();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);
    final quickAmounts = ref.watch(quickAmountsProvider);

    // Listen for transaction success to show modal
    ref.listen<P2PTransferState>(p2pTransferProvider, (previous, next) {
      if (next.transactionResult != null &&
          previous?.transactionResult == null) {
        TransactionSuccessBottomSheet.show(context);
      }
    });

    // Check if recipient exists
    if (state.transferData.recipient == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No recipient selected',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomButtons(context, state),
      body: _buildBody(context, state, quickAmounts),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
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

  Widget _buildBody(
    BuildContext context,
    P2PTransferState state,
    List<double> quickAmounts,
  ) {
    final recipient = state.transferData.recipient!;
    final hasInsufficientBalance = state.transferData.hasInsufficientBalance;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Recipient info
          _buildRecipientCard(context, recipient),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // Amount input card
          _buildAmountCard(
              context, state, hasInsufficientBalance, quickAmounts),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Category dropdown
          _buildCategoryDropdown(context),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Note input
          _buildNoteInput(context),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),
        ],
      ),
    );
  }

  Widget _buildRecipientCard(BuildContext context, RecipientInfo recipient) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppLayout.scaleWidth(context, 20),
            backgroundColor: const Color(0xFF069494),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: AppLayout.scaleWidth(context, 20),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.name,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  recipient.accountNumber,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    P2PTransferState state,
    bool hasInsufficientBalance,
    List<double> quickAmounts,
  ) {
    final isDisabled = state.transferData.amount == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LABEL
          const Text(
            "Amount",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          /// INPUT FIELD (MATCHES DESIGN)
          Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  "₦",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: hasInsufficientBalance ? Colors.red : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color:
                          hasInsufficientBalance ? Colors.red : Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "50.00 - 50,000.00",
                      hintStyle: TextStyle(
                        color: Colors.black26,
                        fontSize: 18,
                      ),
                    ),
                    onChanged: (_) => _updateAmount(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// BALANCE + FEE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Balance: ${_currencyFormat.format(state.transferData.balance)}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "Fee: ${_currencyFormat.format(state.transferData.fee)}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),

          /// ERROR
          if (hasInsufficientBalance) ...[
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                SizedBox(width: 6),
                Text(
                  "Insufficient balance",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          /// QUICK AMOUNTS
          const Text(
            "Quick amounts",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickAmounts.map((amount) {
              final isSelected = state.transferData.amount == amount;

              return GestureDetector(
                onTap: () => _setQuickAmount(amount),
                child: Container(
                  width: 85,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE0F2F1)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "₦${amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFF069494) : Colors.black54,
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

  Widget _buildCategoryDropdown(BuildContext context) {
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
          Text(
            'Category (optional)',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          DropdownButtonFormField<TransactionCategory>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Select Category',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF069494),
                  width: 2,
                ),
              ),
            ),
            items: TransactionCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category.name[0].toUpperCase() + category.name.substring(1),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              if (value != null) {
                ref.read(p2pTransferProvider.notifier).setCategory(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput(BuildContext context) {
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
          Text(
            'Note (optional)',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'What\'s this for?',
              hintStyle: TextStyle(
                color: Colors.black38,
                fontSize: AppLayout.fontSize(context, 14),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF069494),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              ref.read(p2pTransferProvider.notifier).setNote(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, P2PTransferState state) {
    final canSend = state.transferData.amount != null &&
        state.transferData.amount! > 0 &&
        !state.transferData.hasInsufficientBalance;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 30),
          AppLayout.scaleHeight(context, 12),
          AppLayout.scaleWidth(context, 24),
          AppLayout.scaleHeight(context, 30),
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 52),
          child: ElevatedButton(
            onPressed: canSend
                ? () {
                    ConfirmTransferBottomSheet.show(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canSend ? const Color(0xFF069494) : const Color(0xFFB2DFDB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              'Send',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
