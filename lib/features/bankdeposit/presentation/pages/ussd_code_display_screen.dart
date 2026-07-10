import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/provider/funding/funding_provider.dart';

class UssdCodeDisplayScreen extends ConsumerStatefulWidget {
  const UssdCodeDisplayScreen({super.key});

  @override
  ConsumerState<UssdCodeDisplayScreen> createState() =>
      _UssdCodeDisplayScreenState();
}

class _UssdCodeDisplayScreenState extends ConsumerState<UssdCodeDisplayScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = const Duration(minutes: 5, seconds: 00);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        });
      } else {
        timer.cancel();
        _showExpiredDialog();
      }
    });
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _ExpiredDialog(
        ussdCode: ref.read(ussdTransferProvider).data?.ussdCode ?? '',
        onCancel: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
        onGenerate: () {
          Navigator.pop(ctx);
          setState(() {
            _timeRemaining = const Duration(minutes: 4, seconds: 24);
          });
          _startCountdown();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ussdData = ref.watch(ussdTransferProvider).data;

    if (ussdData == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundScreen,
        appBar: _buildAppBar(context),
        body: const Center(child: Text('No USSD data available')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context),
      body: _buildBody(context, ussdData),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () {
          _countdownTimer?.cancel();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Dial USSD code',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, UssdTransferData ussdData) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 20),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Info banner — plain text, no container ──────────────────────
          _buildInfoText(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 36)),

          // ── Bank logo + name ────────────────────────────────────────────
          _buildBankInfo(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // ── USSD code ───────────────────────────────────────────────────
          _buildUssdCode(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // ── Timer italic caption ────────────────────────────────────────
          Text(
            'Dial the code & fund your Account within the allocated time',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: AppColors.primaryTeal,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // ── Countdown — plain spaced numbers, no box borders ────────────
          _buildCountdown(context),

          SizedBox(height: AppLayout.scaleHeight(context, 56)),

          // ── Copy code button ────────────────────────────────────────────
          _buildCopyButton(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 14)),

          // ── Completed payment button ────────────────────────────────────
          _buildCompletedButton(context),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  // ── Info text — plain text on background, no card ────────────────────────
  Widget _buildInfoText(BuildContext context, UssdTransferData ussdData) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: AppColors.textDark,
            height: 1.4,
          ),
          children: [
            const TextSpan(
                text: 'Dial the code below to fund your Kudikit Account with ',
                style: TextStyle(fontSize: 10)),
            TextSpan(
              text: '₦${_formatAmount(ussdData.amount)}',
              style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w400,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bank logo + name ──────────────────────────────────────────────────────
  Widget _buildBankInfo(BuildContext context, UssdTransferData ussdData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Small bank logo circle — matches design size
        _BankLogoCircle(
          bank: ussdData.bank,
          size: AppLayout.scaleWidth(context, 28),
          fontSize: AppLayout.fontSize(context, 9),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 8)),
        Text(
          ussdData.bank.name,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── USSD code — large bold text ───────────────────────────────────────────
  Widget _buildUssdCode(BuildContext context, UssdTransferData ussdData) {
    return Text(
      ussdData.ussdCode,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 30),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCountdown(BuildContext context) {
    final totalMinutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;

    // Split into individual characters to match the spaced-out design
    final minStr = totalMinutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDigit(context, minStr[0]),
        SizedBox(width: AppLayout.scaleWidth(context, 14)),
        _buildDigit(context, minStr[1]),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 10),
          ),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 26),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        _buildDigit(context, secStr[0]),
        SizedBox(width: AppLayout.scaleWidth(context, 14)),
        _buildDigit(context, secStr[1]),
      ],
    );
  }

  Widget _buildDigit(BuildContext context, String digit) {
    return Text(
      digit,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 18),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────
  Widget _buildCopyButton(BuildContext context, UssdTransferData ussdData) {
    return ElevatedButton(
      onPressed: () => _copyCode(context, ussdData.ussdCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        minimumSize: Size(double.infinity, AppLayout.scaleHeight(context, 52)),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
        ),
        elevation: 0,
      ),
      child: Text(
        'Copy code',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletedButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        _countdownTimer?.cancel();
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, AppLayout.scaleHeight(context, 52)),
        side: const BorderSide(color: AppColors.primaryTeal, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
        ),
      ),
      child: Text(
        'Completed payment',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('USSD code copied to clipboard'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ─── Expired Dialog ───────────────────────────────────────────────────────────
// Matches Image 1 exactly:
// - Centred floating card, no top padding gap, code bold at top
// - Single message line below
// - Thin divider
// - Cancel (grey) | Generate (teal) side-by-side text buttons

class _ExpiredDialog extends StatelessWidget {
  final String ussdCode;
  final VoidCallback onCancel;
  final VoidCallback onGenerate;

  const _ExpiredDialog({
    required this.ussdCode,
    required this.onCancel,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 40),
        vertical: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Code + message ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppLayout.scaleWidth(context, 20),
              AppLayout.scaleHeight(context, 24),
              AppLayout.scaleWidth(context, 20),
              AppLayout.scaleHeight(context, 16),
            ),
            child: Column(
              children: [
                Text(
                  ussdCode,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 20),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 10)),
                Text(
                  'This USSD code has expired. Generate a new one',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // ── Action row ────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: onGenerate,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                    ),
                    child: Text(
                      'Generate',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared bank logo circle ──────────────────────────────────────────────────
// Re-declared here so this file is self-contained.
// The exact same class lives in bank_ussd_screen.dart for the selector card.

class _BankLogoCircle extends StatelessWidget {
  final Bank bank;
  final double size;
  final double fontSize;

  const _BankLogoCircle({
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
      child: ClipOval(child: _content()),
    );
  }

  Widget _content() {
    final url = _networkUrl(bank.logo);
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
      );
    }
    return _initials();
  }

  Widget _initials() => Center(
        child: Text(
          _getInitials(bank.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  String? _networkUrl(String logo) {
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

  Color _bankColor(String logo) {
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
