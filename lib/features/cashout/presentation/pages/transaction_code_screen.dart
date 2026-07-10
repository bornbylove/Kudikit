import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/features/agent/domain/entities/cashout_transaction_model.dart';
import 'package:kudipay/features/cashout/presentation/controllers/cashout_provider.dart';
import 'package:kudipay/services/transaction_code_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionCodeScreen extends ConsumerStatefulWidget {
  final CashOutTransaction transaction;
  // Fix Issue 4: agent phone passed through so Call Agent works correctly
  final String? agentPhone;

  const TransactionCodeScreen({
    super.key,
    required this.transaction,
    this.agentPhone,
  });

  @override
  ConsumerState<TransactionCodeScreen> createState() =>
      _TransactionCodeScreenState();
}

class _TransactionCodeScreenState extends ConsumerState<TransactionCodeScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;
  final _txService = TransactionCodeService();

  @override
  void initState() {
    super.initState();
    _remaining = widget.transaction.timeRemaining;
    if (_remaining.isNegative) {
      _isExpired = true;
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = widget.transaction.expiresAt.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        setState(() => _isExpired = true);
        ref.read(cashOutProvider.notifier).markExpired();
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String get _formattedTime {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _formattedCode =>
      _txService.formatCodeForDisplay(widget.transaction.transactionCode);

  Future<void> _callAgent() async {
    final phone = widget.agentPhone ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _onReceived() async {
    if (_isExpired) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2BA89A)),
            SizedBox(height: 16),
            Text('Recording transaction...'),
          ],
        ),
      ),
    );

    await ref.read(cashOutProvider.notifier).confirmReceived();

    if (mounted) {
      Navigator.of(context).pop(); // close dialog

      // Show success and pop all the way back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction recorded successfully!'),
          backgroundColor: Color(0xFF2BA89A),
        ),
      );

      // Navigate back to root (transfer menu)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Agent Details',
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
          children: [
            // Agent card
            _buildAgentCard(),
            const SizedBox(height: 16),

            // Transaction code card
            _buildCodeCard(),
            const SizedBox(height: 16),

            // Summary
            _buildSummaryCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isExpired ? null : _onReceived,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2BA89A),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              _isExpired ? 'Code Expired' : 'Received',
              style: TextStyle(
                color: _isExpired ? Colors.black38 : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Agent avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2BA89A).withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                widget.transaction.agentName.isNotEmpty
                    ? widget.transaction.agentName[0]
                    : 'A',
                style: const TextStyle(
                  color: Color(0xFF2BA89A),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.transaction.agentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 16, color: Color(0xFF2BA89A)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Available',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _callAgent,
                  icon: const Icon(Icons.phone_outlined,
                      size: 13, color: Colors.black54),
                  label: const Text(
                    'Call Agent',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Your Transaction Code',
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          Text(
            _formattedCode,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2BA89A),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          if (_isExpired)
            const Text(
              'Code expired',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Expires in: ',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF5A623),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'You will receive',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const Spacer(),
              Text(
                '₦${_fmtAmount(widget.transaction.withdrawalAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2BA89A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Commission (${((widget.transaction.commission / widget.transaction.withdrawalAmount) * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const Spacer(),
              Text(
                '₦${_fmtAmount(widget.transaction.commission)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double amount) {
    final str = amount.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.$decPart';
  }
}
