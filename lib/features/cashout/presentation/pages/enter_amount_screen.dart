import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/features/agent/domain/entities/agent_model.dart';
import 'package:kudipay/shared/widgets/confirm_bottomsheet.dart';
import 'package:kudipay/features/cashout/presentation/controllers/cashout_provider.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/wallet/presentation/controllers/wallet_controllers.dart';

import 'transaction_code_screen.dart';

class EnterAmountScreen extends ConsumerStatefulWidget {
  final AgentModel agent;

  const EnterAmountScreen({super.key, required this.agent});

  @override
  ConsumerState<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends ConsumerState<EnterAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0;
  bool _showFeeBreakdown = false;

  static const List<double> _quickAmounts = [200, 1000, 2000, 3000, 5000, 9999];

  double get _commission => _amount * (widget.agent.commissionPercent / 100);
  double get _totalDebit => _amount + _commission;

  bool get _isValid =>
      _amount >= widget.agent.minWithdrawal &&
      _amount <= widget.agent.maxWithdrawal &&
      _amount <= widget.agent.availableCash;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    setState(() {
      _amount = amount;
      _amountController.text = amount.toStringAsFixed(0);
      _showFeeBreakdown = amount > 0;
    });
  }

  void _onAmountChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
    setState(() {
      _amount = parsed;
      _showFeeBreakdown = parsed > 0;
    });
  }

  void _continue() {
    if (!_isValid) return;

    // Read live user data from providers — no hardcoding.
    final wallet = ref.read(walletProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmBottomSheet(
        agent: widget.agent,
        withdrawalAmount: _amount,
        commission: _commission,
        totalDebit: _totalDebit,
        onConfirm: _processTransaction,
        onCancel: () => Navigator.pop(context),
        userAccountNumber: wallet.accountNumber,
        userName: wallet.accountName,
        userBalance: wallet.balance,
      ),
    );
  }

  Future<void> _processTransaction() async {
    Navigator.pop(context); // close bottom sheet

    // Read live user data from providers — no hardcoding.
    final user = ref.read(currentUserProvider);
    final wallet = ref.read(walletProvider);

    final userId = user?.userId ?? '';
    final userAccountNumber = wallet.accountNumber;
    final userName = wallet.accountName;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to process: user session expired. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transaction =
        await ref.read(cashOutProvider.notifier).createTransaction(
              amount: _amount,
              userId: userId,
              userAccountNumber: userAccountNumber,
              userName: userName,
            );

    if (transaction != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionCodeScreen(
            transaction: transaction,
            agentPhone: widget.agent.phoneNumber,
          ),
        ),
      );
    } else if (mounted) {
      final error = ref.read(cashOutProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Transaction failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashOutProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Enter Amount',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account number (read-only from agent)
                  const Text(
                    'Account Number',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.agent.accountNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount input
                  const Text(
                    'Amount to Withdraw',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onAmountChanged,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      prefixText: '? ',
                      prefixStyle:
                          const TextStyle(fontSize: 15, color: Colors.black54),
                      hintText:
                          '${_fmt(widget.agent.minWithdrawal)} - ${_fmt(widget.agent.maxWithdrawal)}',
                      hintStyle:
                          const TextStyle(color: Colors.black26, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF2BA89A), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick amount chips
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final chipWidth = (constraints.maxWidth - 16) / 3;
                      final aspectRatio = chipWidth / 38;
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: aspectRatio,
                        children: _quickAmounts.map((amount) {
                          final isSelected = _amount == amount;
                          return GestureDetector(
                            onTap: () => _setAmount(amount),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2BA89A)
                                        .withValues(alpha: 0.1)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF2BA89A),
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '?${_fmt(amount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF2BA89A)
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fee breakdown
            if (_showFeeBreakdown) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fee Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FeeRow(
                      label: 'Withdrawal amount',
                      value: '?${_fmtAmount(_amount)}',
                    ),
                    const SizedBox(height: 8),
                    _FeeRow(
                      label: 'Commission (${widget.agent.commissionPercent}%)',
                      value: '?${_fmtAmount(_commission)}',
                    ),
                    const Divider(height: 20),
                    _FeeRow(
                      label: 'Total to Debit',
                      value: '?${_fmtAmount(_totalDebit)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2BA89A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF2BA89A),
                    size: 16,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You'll receive a 6-digit code to show the agent for cash collection. The code expires in 15 minutes.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed:
                _isValid && !state.isProcessingTransaction ? _continue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2BA89A),
              disabledBackgroundColor:
                  const Color(0xFF2BA89A).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: state.isProcessingTransaction
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  String _fmt(double amount) => amount.toStringAsFixed(0);

  String _fmtAmount(double amount) => _addCommas(amount.toStringAsFixed(2));

  String _addCommas(String numStr) {
    final parts = numStr.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}$decPart';
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _FeeRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isTotal ? Colors.black87 : Colors.black45,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isTotal ? const Color(0xFF2BA89A) : Colors.black87,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
