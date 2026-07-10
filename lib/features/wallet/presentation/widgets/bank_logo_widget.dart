// lib/features/wallet/presentation/widgets/bank_logo_widget.dart
//
// Shared bank logo circle used by:
//   - bank_ussd_screen.dart
//   - ussd_code_display_screen.dart
//   - select_bank.dart
//
// Previously copy-pasted as a private _BankLogoCircle in each file.

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

/// A circular avatar showing the bank's logo (network image) or
/// coloured initials as a fallback.
class BankLogoWidget extends StatelessWidget {
  final Bank bank;
  final double size;
  final double fontSize;

  const BankLogoWidget({
    super.key,
    required this.bank,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bankColor(bank.logo),
        shape: BoxShape.circle,
      ),
      child: ClipOval(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final url = _networkUrl(bank.logo);
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsWidget(),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() => Center(
        child: Text(
          _initials(bank.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  // ── Static helpers ────────────────────────────────────────────────────────

  static String? _networkUrl(String logo) {
    const Map<String, String> logos = {
      'gtbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/GTBank_logo.svg/200px-GTBank_logo.svg.png',
      'firstbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/First_bank_of_Nigeria_plc_logo.png/200px-First_bank_of_Nigeria_plc_logo.png',
      'wema':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Wema_Bank_Logo.png/200px-Wema_Bank_Logo.png',
      'uba':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/United_Bank_for_Africa_Logo.svg/200px-United_Bank_for_Africa_Logo.svg.png',
      'fcmb':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/FCMB_logo.png/200px-FCMB_logo.png',
      'sterling':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Sterling_Bank_Logo.png/200px-Sterling_Bank_Logo.png',
    };
    return logos[logo.toLowerCase()];
  }

  static Color _bankColor(String logo) {
    switch (logo.toLowerCase()) {
      case 'gtbank':
        return const Color(0xFFFF6600);
      case 'firstbank':
        return const Color(0xFF002244);
      case 'wema':
        return const Color(0xFF722C7A);
      case 'uba':
        return const Color(0xFFD32F2F);
      case 'fcmb':
        return const Color(0xFF7B1FA2);
      case 'sterling':
        return const Color(0xFFD32F2F);
      case 'parallex':
        return const Color(0xFF1E3A8A);
      case 'globus':
        return const Color(0xFFD32F2F);
      default:
        return AppColors.primaryTeal;
    }
  }

  static String _initials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
