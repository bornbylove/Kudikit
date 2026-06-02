// ============================================================================
// lib/formatting/widget/network_logo.dart
//
// Branded network logo widgets for all 4 Nigerian mobile networks.
// Uses pure Flutter drawing — no external image assets required.
// Also contains the reusable NetworkDropdown widget used on both
// AirtimePhoneScreen and DataPhoneScreen.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/model/bill/bill_model.dart';


// ============================================================================
// NetworkLogo
// Renders the correct branded logo for a Nigerian mobile network.
// ============================================================================

class NetworkLogo extends StatelessWidget {
  final NetworkProvider network;
  final double size;

  const NetworkLogo({
    Key? key,
    required this.network,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildLogo(),
    );
  }

  Widget _buildLogo() {
    switch (network) {
      case NetworkProvider.mtn:
        return _MtnLogo(size: size);
      case NetworkProvider.airtel:
        return _AirtelLogo(size: size);
      case NetworkProvider.glo:
        return _GloLogo(size: size);
      case NetworkProvider.nineMobile:
        return _NineMobileLogo(size: size);
    }
  }
}

// ── MTN: yellow circle, dark-blue "MTN" text ─────────────────────────────────
class _MtnLogo extends StatelessWidget {
  final double size;
  const _MtnLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFCC00),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'MTN',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF003087),
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Airtel: red circle, white "airtel" text ───────────────────────────────────
class _AirtelLogo extends StatelessWidget {
  final double size;
  const _AirtelLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE3001B),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'airtel',
          style: TextStyle(
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Glo: green circle, white "glo" text ──────────────────────────────────────
class _GloLogo extends StatelessWidget {
  final double size;
  const _GloLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF009A44),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'glo',
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── 9mobile: dark-green circle, white "9" text ───────────────────────────────
class _NineMobileLogo extends StatelessWidget {
  final double size;
  const _NineMobileLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF006633),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '9',
          style: TextStyle(
            fontSize: size * 0.46,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NetworkProvider extension helpers
// ============================================================================

extension NetworkProviderExt on NetworkProvider {
  String get displayName {
    switch (this) {
      case NetworkProvider.mtn:        return 'MTN';
      case NetworkProvider.airtel:     return 'Airtel';
      case NetworkProvider.glo:        return 'Glo';
      case NetworkProvider.nineMobile: return '9mobile';
    }
  }

  Color get brandColor {
    switch (this) {
      case NetworkProvider.mtn:        return const Color(0xFFFFCC00);
      case NetworkProvider.airtel:     return const Color(0xFFE3001B);
      case NetworkProvider.glo:        return const Color(0xFF009A44);
      case NetworkProvider.nineMobile: return const Color(0xFF006633);
    }
  }
}

// ============================================================================
// NetworkDropdown
//
// Reusable animated dropdown used on both AirtimePhoneScreen and
// DataPhoneScreen. Shows the selected network with a "Suggested" badge
// on the auto-detected network.
// ============================================================================

class NetworkDropdown extends StatelessWidget {
  final NetworkProvider? selectedNetwork;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<NetworkProvider> onSelect;

  const NetworkDropdown({
    Key? key,
    required this.selectedNetwork,
    required this.isOpen,
    required this.onToggle,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selector button ──────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isOpen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    )
                  : BorderRadius.circular(12),
              boxShadow: isOpen
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Network logo or placeholder
                if (selectedNetwork != null) ...[
                  NetworkLogo(network: selectedNetwork!, size: 28),
                  const SizedBox(width: 10),
                ] else ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cell_tower,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                Text(
                  selectedNetwork?.displayName ?? 'Select Network',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selectedNetwork != null
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey,
                  ),
                ),

                const Spacer(),

                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF1A1A2E),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Dropdown options ─────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: NetworkProvider.values.map((network) {
                return _NetworkOption(
                  network: network,
                  isSuggested: network == selectedNetwork,
                  onTap: () => onSelect(network),
                );
              }).toList(),
            ),
          ),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _NetworkOption extends StatelessWidget {
  final NetworkProvider network;
  final bool isSuggested;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.network,
    required this.isSuggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            NetworkLogo(network: network, size: 28),
            const SizedBox(width: 12),
            Text(
              network.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
            if (isSuggested) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Suggested',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF069494),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}