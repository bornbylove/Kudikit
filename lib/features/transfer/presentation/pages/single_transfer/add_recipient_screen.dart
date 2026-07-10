import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/features/transfer/domain/entities/bulk_transfer_model.dart';
import 'package:kudipay/features/transfer/presentation/pages/bulk_transfer/bulk_transfer_preview.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/bank_selection_bottom_sheet.dart';

class AddRecipientsManuallyScreen extends ConsumerStatefulWidget {
  const AddRecipientsManuallyScreen({super.key});

  @override
  ConsumerState<AddRecipientsManuallyScreen> createState() =>
      _AddRecipientsManuallyScreenState();
}

class _AddRecipientsManuallyScreenState
    extends ConsumerState<AddRecipientsManuallyScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  final TextEditingController _equalSplitController = TextEditingController();

  @override
  void dispose() {
    _equalSplitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkTransferProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add manually',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 40),
                    height: AppLayout.scaleWidth(context, 40),
                    child: CircularProgressIndicator(
                      value: 0.36,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '36%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distribution Type Section
                  _buildDistributionTypeSection(context, state),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Recipients List
                  _buildRecipientsListSection(context, state),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Summary Section
                  _buildSummarySection(context, state),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Schedule Transfer Toggle
                  _buildScheduleToggle(context, state),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Fee Information
                  _buildFeeInformation(context),

                  SizedBox(height: AppLayout.scaleHeight(context, 100)),
                ],
              ),
            ),
          ),

          // Bottom Button
          _buildBottomButton(context, state),
        ],
      ),
    );
  }

  Widget _buildDistributionTypeSection(
      BuildContext context, BulkTransferState state) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you want to set amounts?',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Account Type Toggle
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  context: context,
                  text: 'Solo Amount',
                  isSelected: state.distributionType ==
                      AmountDistributionType.soloAmount,
                  onTap: () {
                    ref
                        .read(bulkTransferProvider.notifier)
                        .setDistributionType(AmountDistributionType.soloAmount);
                    _equalSplitController.clear();
                  },
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: _buildToggleButton(
                  context: context,
                  text: 'Equal Split',
                  isSelected: state.distributionType ==
                      AmountDistributionType.equalSplit,
                  onTap: () {
                    ref
                        .read(bulkTransferProvider.notifier)
                        .setDistributionType(AmountDistributionType.equalSplit);
                  },
                ),
              ),
            ],
          ),

          if (state.distributionType == AmountDistributionType.equalSplit) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Amount per recipient field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount per recipient',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                TextField(
                  controller: _equalSplitController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '₦ 10,000.00',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: AppLayout.fontSize(context, 16),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F9F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                      vertical: AppLayout.scaleHeight(context, 16),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final amount = double.tryParse(value) ?? 0;
                      ref
                          .read(bulkTransferProvider.notifier)
                          .setAmountPerRecipient(amount);
                    } else {
                      ref
                          .read(bulkTransferProvider.notifier)
                          .setAmountPerRecipient(0);
                    }
                  },
                ),
              ],
            ),

            // Show total calculation
            if (state.amountPerRecipient != null &&
                state.amountPerRecipient! > 0 &&
                state.recipientCount > 0) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'Total: ${_currencyFormat.format(state.calculatedTotalAmount)} (${state.recipientCount} recipients × ${_currencyFormat.format(state.amountPerRecipient!)})',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12),
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecipientsListSection(
      BuildContext context, BulkTransferState state) {
    final isSoloAmount =
        state.distributionType == AmountDistributionType.soloAmount;

    // Always show at least one recipient card
    if (state.recipients.isEmpty) {
      // Initialize with one empty recipient
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newRecipient = BulkTransferRecipient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '',
          accountType: TransferAccountType.kudikit,
          accountNumber: '',
        );
        ref.read(bulkTransferProvider.notifier).addRecipient(newRecipient);
      });
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipients header with count badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recipients',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 10),
                vertical: AppLayout.scaleHeight(context, 4),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.recipients.length}/15',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 12)),
        ...state.recipients.asMap().entries.map((entry) {
          final index = entry.key;
          final recipient = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: AppLayout.scaleHeight(context, 12),
            ),
            child: _RecipientCard(
              recipientNumber: index + 1,
              recipient: recipient,
              showAmount: isSoloAmount,
              onAccountTypeChanged: (type) {
                // Update recipient account type
                final updated = recipient.copyWith(accountType: type);
                ref
                    .read(bulkTransferProvider.notifier)
                    .updateRecipient(recipient.id, updated);
              },
              onDelete: state.recipients.length > 1
                  ? () {
                      ref
                          .read(bulkTransferProvider.notifier)
                          .removeRecipient(recipient.id);
                    }
                  : null,
              onUpdate: (updatedRecipient) {
                ref
                    .read(bulkTransferProvider.notifier)
                    .updateRecipient(recipient.id, updatedRecipient);
              },
            ),
          );
        }),

        // Add Recipient Button — available in both distribution modes
        if (state.recipients.length < 15)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final newRecipient = BulkTransferRecipient(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: '',
                    accountType: TransferAccountType.kudikit,
                    accountNumber: '',
                  );
                  ref
                      .read(bulkTransferProvider.notifier)
                      .addRecipient(newRecipient);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primaryTeal,
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 8)),
                      Text(
                        '+ Add Recipient',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, BulkTransferState state) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Only show recipient count for Equal Split
          if (state.distributionType == AmountDistributionType.equalSplit) ...[
            _buildSummaryRow(
              context,
              'Recipient(s)',
              '${state.recipientCount}',
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
          ],

          _buildSummaryRow(
            context,
            'Total transfer amount',
            _currencyFormat.format(state.calculatedTotalAmount),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          _buildSummaryRow(
            context,
            'Bank transfer fees',
            _currencyFormat.format(state.totalBankFees),
          ),

          // Always show Total Debit
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          _buildSummaryRow(
            context,
            'Total Debit',
            _currencyFormat.format(state.totalDebit),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.black,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleToggle(BuildContext context, BulkTransferState state) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
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
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: AppLayout.scaleWidth(context, 20),
                color: Colors.grey[700],
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Transfer',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 2)),
                    Text(
                      'Transfer will be processed immediately after confirmation',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isScheduled,
                onChanged: (value) {
                  ref
                      .read(bulkTransferProvider.notifier)
                      .setScheduledTransfer(isScheduled: value);
                },
                activeThumbColor: AppColors.primaryTeal,
              ),
            ],
          ),
          if (state.isScheduled) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Date field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'dd/mm/yy',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: AppLayout.fontSize(context, 15),
                    ),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F9F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                      vertical: AppLayout.scaleHeight(context, 16),
                    ),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      ref
                          .read(bulkTransferProvider.notifier)
                          .setScheduledTransfer(
                            isScheduled: true,
                            date: date,
                            time: state.scheduledTime,
                          );
                    }
                  },
                ),
              ],
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Time field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: '00:00',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: AppLayout.fontSize(context, 15),
                    ),
                    suffixIcon: Icon(
                      Icons.access_time,
                      color: Colors.grey[600],
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F9F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                      vertical: AppLayout.scaleHeight(context, 16),
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      ref
                          .read(bulkTransferProvider.notifier)
                          .setScheduledTransfer(
                            isScheduled: true,
                            date: state.scheduledDate,
                            time: time,
                          );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeInformation(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF90CAF9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF1976D2),
            size: AppLayout.scaleWidth(context, 20),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee Information',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  '• Kudikit transfers: Free\n• Bank transfers: ₦10 per recipient\n• 5+ bank transfers: 30% bulk discount applied',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: const Color(0xFF0D47A1),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, BulkTransferState state) {
    final recipientCount = state.recipients.length;
    final buttonText = recipientCount == 0
        ? 'Continue with 0 recipient'
        : 'Continue with $recipientCount recipient${recipientCount > 1 ? 's' : ''}';

    final isEnabled = state.recipients.isNotEmpty && state.isValid;

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 52),
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BulkTransferPreviewScreen(),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEnabled ? AppColors.primaryTeal : const Color(0xFFB8E6CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
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

  Widget _buildToggleButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 14),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : const Color(0xFFF5F9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

// Recipient Card Widget
class _RecipientCard extends ConsumerStatefulWidget {
  final int recipientNumber;
  final BulkTransferRecipient? recipient;
  final bool showAmount;
  final Function(TransferAccountType) onAccountTypeChanged;
  final VoidCallback? onDelete;
  final Function(BulkTransferRecipient) onUpdate;

  const _RecipientCard({
    required this.recipientNumber,
    this.recipient,
    this.showAmount = false,
    required this.onAccountTypeChanged,
    this.onDelete,
    required this.onUpdate,
  });

  @override
  ConsumerState<_RecipientCard> createState() => _RecipientCardState();
}

class _RecipientCardState extends ConsumerState<_RecipientCard> {
  late TransferAccountType _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedBank;
  String? _selectedBankCode;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.recipient?.accountType ?? TransferAccountType.kudikit;

    if (widget.recipient != null) {
      _nameController.text = widget.recipient!.name;
      _accountController.text = widget.recipient!.accountNumber;
      _phoneController.text = widget.recipient!.phoneNumber ?? '';
      _narrationController.text = widget.recipient!.narration ?? '';
      _selectedBank = widget.recipient!.bankName;
      _selectedBankCode = widget.recipient!.bankCode;
      if (widget.recipient!.amount != null) {
        _amountController.text = widget.recipient!.amount!.toStringAsFixed(0);
      }
    }

    // Add listeners to update provider
    _nameController.addListener(_updateRecipient);
    _accountController.addListener(_updateRecipient);
    _phoneController.addListener(_updateRecipient);
    _narrationController.addListener(_updateRecipient);
    _amountController.addListener(_updateRecipient);
  }

  void _updateRecipient() {
    if (widget.recipient == null) return;

    final amount = _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

    final updated = widget.recipient!.copyWith(
      name: _nameController.text,
      accountNumber: _selectedType == TransferAccountType.kudikit
          ? _phoneController.text
          : _accountController.text,
      phoneNumber: _selectedType == TransferAccountType.kudikit
          ? _phoneController.text
          : null,
      bankName: _selectedBank,
      bankCode: _selectedBankCode,
      narration: _narrationController.text.isNotEmpty
          ? _narrationController.text
          : null,
      amount: amount,
      accountType: _selectedType,
    );

    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _phoneController.dispose();
    _narrationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _nameController.text.isNotEmpty;
    final hasAccountNumber = _selectedType == TransferAccountType.kudikit
        ? _phoneController.text.isNotEmpty
        : _accountController.text.isNotEmpty;
    final hasAmount =
        widget.showAmount ? _amountController.text.isNotEmpty : true;
    final isComplete = hasName && hasAccountNumber && hasAmount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? AppColors.primaryTeal : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: AppLayout.scaleWidth(context, 32),
                  height: AppLayout.scaleWidth(context, 32),
                  decoration: BoxDecoration(
                    color:
                        isComplete ? AppColors.primaryTeal : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isComplete ? Icons.check : null,
                      color: Colors.white,
                      size: AppLayout.scaleWidth(context, 18),
                    ),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 12)),
                Text(
                  'Recipient ${widget.recipientNumber}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: AppLayout.scaleWidth(context, 22),
                    ),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Name Field
            _buildTextField(
              context: context,
              label: 'Name',
              hint: 'John Doe',
              controller: _nameController,
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Account Type Toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Type',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                Row(
                  children: [
                    Expanded(
                      child: _buildAccountTypeButton(
                        context: context,
                        text: 'Kudikit',
                        isSelected:
                            _selectedType == TransferAccountType.kudikit,
                        onTap: () {
                          setState(() {
                            _selectedType = TransferAccountType.kudikit;
                          });
                          widget.onAccountTypeChanged(
                              TransferAccountType.kudikit);
                          _updateRecipient();
                        },
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: _buildAccountTypeButton(
                        context: context,
                        text: 'Bank',
                        isSelected: _selectedType == TransferAccountType.bank,
                        onTap: () {
                          setState(() {
                            _selectedType = TransferAccountType.bank;
                          });
                          widget.onAccountTypeChanged(TransferAccountType.bank);
                          _updateRecipient();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Account Number or Phone Number
            if (_selectedType == TransferAccountType.kudikit)
              _buildTextField(
                context: context,
                label: 'Phone Number',
                hint: '08124608695',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              )
            else ...[
              _buildTextField(
                context: context,
                label: 'Account Number',
                hint: '0123456789',
                controller: _accountController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Bank Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => BankSelectionBottomSheet(
                          onBankSelected: (bank) {
                            setState(() {
                              _selectedBank = bank.name;
                              _selectedBankCode = bank.code;
                            });
                            _updateRecipient();
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 16),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedBank ?? 'Select Bank',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 15),
                              color: _selectedBank != null
                                  ? Colors.black87
                                  : Colors.grey[400],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: AppLayout.scaleWidth(context, 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Narration
            _buildTextField(
              context: context,
              label: 'Narration (optional)',
              hint: 'Payment purpose',
              controller: _narrationController,
            ),

            if (widget.showAmount) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              _buildTextField(
                context: context,
                label: 'Amount',
                hint: '₦ 10,000.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: AppLayout.fontSize(context, 15),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F9F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTypeButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 14),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : const Color(0xFFF5F9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
