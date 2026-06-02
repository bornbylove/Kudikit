import 'package:flutter/material.dart';
import 'package:kudipay/model/agent/agent_model.dart';


class AgentListTile extends StatelessWidget {
  final AgentModel agent;
  final VoidCallback onTap;

  const AgentListTile({
    super.key,
    required this.agent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _AgentAvatar(
              imageUrl: agent.profileImageUrl,
              name: agent.shopName,
              size: 46,
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        agent.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFF2BA89A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Stars
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: i < agent.rating.floor()
                              ? const Color(0xFFF5A623)
                              : Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${agent.distanceKm?.toStringAsFixed(1) ?? '?'}km away',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${agent.commissionPercent}% fee',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2BA89A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: agent.isAvailable
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        agent.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              agent.isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

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
                errorBuilder: (_, __, ___) => _initials(name, size),
              ),
            )
          : _initials(name, size),
    );
  }

  Widget _initials(String name, double size) {
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