import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/shared_widget.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentDashboardProvider);
    final notifier = ref.read(agentDashboardProvider.notifier);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            const Text(
              'Hello, Welcome',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Michael's Store",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Availability toggle card
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.isAvailable
                              ? 'Accepting withdrawal requests'
                              : 'Not accepting requests',
                          style: const TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.isAvailable,
                    onChanged: (_) => notifier.toggleAvailability(),
                    activeThumbColor: kTeal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Earning label
            const Text(
              "Today's Earning",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 12),

            // Stats row — responsive
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Commission',
                        value: '₦${_fmtAmount(state.todayCommission)}',
                        sub: '↗ 12% vs yesterday',
                        subColor: kTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Transactions',
                        value: '${state.todayTransactions}',
                        sub: '₦${_fmtAmount(state.totalAmount)} total',
                        subColor: kTextMid,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Mini icon stats row
            SectionCard(
              child: Row(
                children: [
                  _MiniStat(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: kTeal.withValues(alpha: 0.1),
                    iconColor: kTeal,
                  ),
                  _MiniStat(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: Colors.orange.withValues(alpha: 0.1),
                    iconColor: Colors.orange,
                  ),
                  _MiniStat(
                    icon: Icons.show_chart_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: Colors.blue.withValues(alpha: 0.1),
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pending requests
            const Text(
              "Today's Earning",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 12),

            if (state.pendingRequests.isEmpty)
              const SectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No pending requests',
                      style: TextStyle(color: kTextMid, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ...state.pendingRequests.map(
                (req) => _RequestCard(
                  request: req,
                  onAccept: () => notifier.acceptRequest(req),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _fmtAmount(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color subColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kTextMid)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: subColor)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextMid)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;

  const _RequestCard({required this.request, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${_fmtAmount(request['amount'] ?? 0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: kTextMid),
                        const SizedBox(width: 3),
                        Text(
                          request['distance'] ?? '',
                          style: const TextStyle(fontSize: 11, color: kTextMid),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time,
                            size: 12, color: kTextMid),
                        const SizedBox(width: 3),
                        Text(
                          request['timeAgo'] ?? '',
                          style: const TextStyle(fontSize: 11, color: kTextMid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+₦${_fmtAmount(request['commission'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Commission',
                    style: TextStyle(fontSize: 11, color: kTextMid),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accept Request',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
