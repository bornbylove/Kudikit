import 'package:flutter/material.dart';
import 'package:kudipay/model/agent/agent_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'enter_amount_screen.dart';

class AgentDetailsScreen extends StatelessWidget {
  final AgentModel agent;

  const AgentDetailsScreen({super.key, required this.agent});

  void _callAgent(BuildContext context) async {
    final uri = Uri.parse('tel:${agent.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make call')),
        );
      }
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
            // Agent profile card
            _buildProfileCard(context),
            const SizedBox(height: 16),

            // Stats row
            _buildStatsRow(),
            const SizedBox(height: 16),

            // Withdrawal limit
            _buildInfoCard(
              title: 'Withdrawal Limit',
              rows: [
                _InfoRow('Minimum', '₦${_fmt(agent.minWithdrawal)}'),
                _InfoRow('Maximum', '₦${_fmt(agent.maxWithdrawal)}'),
              ],
            ),
            const SizedBox(height: 12),

            // Operating hours
            _buildInfoCard(
              title: 'Operating Hours',
              rows: [
                _InfoRow('Time', '${agent.openingTime} - ${agent.closingTime}'),
                _InfoRow('Availability', agent.operatingDays),
              ],
            ),
            const SizedBox(height: 12),

            // Location
            _buildInfoCard(
              title: 'Location',
              rows: [
                _InfoRow('Location', agent.address),
              ],
            ),
            const SizedBox(height: 12),

            // Languages
            _buildLanguagesCard(),
            const SizedBox(height: 80), // space for button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EnterAmountScreen(agent: agent),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2BA89A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue to Withdrawal',
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

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _AgentAvatar(
            imageUrl: agent.profileImageUrl,
            name: agent.shopName,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agent.shopName,
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
                const SizedBox(height: 2),
                Text(
                  'Account Number: ${agent.accountNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2BA89A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5A623), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${agent.rating} (${agent.totalTransactions} transactions)',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: agent.isAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      agent.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: agent.isAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _callAgent(context),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '${agent.commissionPercent}%',
            label: 'Commission',
          ),
          _buildDivider(),
          _StatItem(
            value: '${agent.distanceKm?.toStringAsFixed(1) ?? '?'}km',
            label: 'Distance',
          ),
          _buildDivider(),
          _StatItem(
            value: '₦${_compactAmount(agent.availableCash)}',
            label: 'Available',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: Colors.black12);
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      row.label,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                    const Spacer(),
                    Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLanguagesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: agent.languages
                .map(
                  (lang) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lang,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000)
      return '${amount ~/ 1000},${(amount % 1000).toStringAsFixed(0).padLeft(3, '0')}';
    return amount.toStringAsFixed(0);
  }

  String _compactAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}

// Re-export avatar from list tile
class _AgentAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const _AgentAvatar({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2BA89A).withValues(alpha: 0.15),
      ),
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(),
              ),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFF2BA89A),
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
