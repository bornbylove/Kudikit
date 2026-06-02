import 'package:flutter/material.dart';
import 'package:kudipay/model/agent/agent_model.dart';


class ConfirmBottomSheet extends StatelessWidget {
  final AgentModel agent;
  final double withdrawalAmount;
  final double commission;
  final double totalDebit;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  // FIX #7: User data passed as constructor params — not hardcoded static consts
  final String userAccountNumber;
  final String userName;
  final double userBalance;

  const ConfirmBottomSheet({
    super.key,
    required this.agent,
    required this.withdrawalAmount,
    required this.commission,
    required this.totalDebit,
    required this.onConfirm,
    required this.onCancel,
    required this.userAccountNumber,
    required this.userName,
    required this.userBalance,
  });

  @override
  Widget build(BuildContext context) {
    // FIX #2: Constrain sheet height to 90% of screen. Wrap content in
    // SingleChildScrollView so nothing clips when keyboard opens on small devices.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kindly confirm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCancel,
                  child: const Icon(Icons.close, size: 20, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total debit amount
            Text(
              'N${_fmtAmount(totalDebit)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2BA89A),
              ),
            ),
            const SizedBox(height: 20),
            // Agent account details card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Account details',
                          style: TextStyle(fontSize: 12, color: Colors.black45)),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          '${agent.accountNumber} | ${agent.bankName}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Account name',
                          style: TextStyle(fontSize: 12, color: Colors.black45)),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          agent.ownerName,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Paying from',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
            ),
            const SizedBox(height: 8),
            // User account card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2BA89A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(userName),
                        style: const TextStyle(
                          color: Color(0xFF2BA89A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$userName  $userAccountNumber',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'N ${_fmtAmount(userBalance)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2BA89A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFF2BA89A),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2BA89A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Proceed',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : 'U';
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