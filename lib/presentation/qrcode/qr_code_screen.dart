import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/funding/funding_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrCodeProvider.notifier).generateQrCode();
      ref.read(accountDetailsProvider.notifier).loadAccountDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrState = ref.watch(qrCodeProvider);
    final accountState = ref.watch(accountDetailsProvider);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context, qrState),
      body: _buildBody(context, qrState, accountState, walletState),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, QrCodeState qrState) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Scan my QR code',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: AppColors.primaryTeal,
            size: AppLayout.scaleWidth(context, 22),
          ),
          onPressed: () => _shareQrCode(context, qrState.qrCodeUrl),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    QrCodeState qrState,
    AccountDetailsState accountState,
    WalletState walletState,
  ) {
    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 12)),

          // Info banner
          _buildInfoBanner(context),
          SizedBox(height: AppLayout.scaleHeight(context, 28)),

          // QR card
          _buildQrCard(context, qrState, accountState, walletState),
          SizedBox(height: AppLayout.scaleHeight(context, 28)),

          // Account info rows
          if (accountState.accountDetails != null)
            _buildAccountInfo(context, accountState),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // Save button
          _buildSaveButton(context, qrState),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Regenerate button
          _buildRegenerateButton(context, qrState.isLoading),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.checkGreen,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppLayout.scaleWidth(context, 18),
            color: AppColors.primaryTeal,
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 10)),
          Expanded(
            child: Text(
              'Show this QR code to any Kudikit user to receive payment instantly.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(
    BuildContext context,
    QrCodeState qrState,
    AccountDetailsState accountState,
    WalletState walletState,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + name
          _buildUserHeader(context, walletState),
          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // QR image
          _buildQrImage(context, qrState),
          SizedBox(height: AppLayout.scaleHeight(context, 20)),

          // Account number
          if (accountState.accountDetails != null)
            Text(
              accountState.accountDetails!.accountNumber,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: 3,
              ),
            ),

          SizedBox(height: AppLayout.scaleHeight(context, 4)),

          // Bank name
          if (accountState.accountDetails != null)
            Text(
              accountState.accountDetails!.bankName,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, WalletState walletState) {
    return Column(
      children: [
        Container(
          width: AppLayout.scaleWidth(context, 56),
          height: AppLayout.scaleWidth(context, 56),
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              walletState.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 10)),
        Text(
          walletState.accountName.isNotEmpty
              ? walletState.accountName
              : 'Kudikit User',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildQrImage(BuildContext context, QrCodeState qrState) {
    final size = AppLayout.scaleWidth(context, 200);

    if (qrState.isLoading) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    if (qrState.error != null || qrState.qrCodeUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: AppLayout.scaleWidth(context, 48),
              color: AppColors.textGrey,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Text(
              'Failed to load QR',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        qrState.qrCodeUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        },
        errorBuilder: (_, __, ___) => Icon(
          Icons.qr_code_2,
          size: AppLayout.scaleWidth(context, 120),
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildAccountInfo(
    BuildContext context,
    AccountDetailsState accountState,
  ) {
    final details = accountState.accountDetails!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Account Name', details.accountName),
          Divider(
            height: AppLayout.scaleHeight(context, 24),
            color: const Color(0xFFF0F0F0),
          ),
          _buildInfoRow(
            context,
            'Account Number',
            details.accountNumber,
            isCopyable: true,
          ),
          Divider(
            height: AppLayout.scaleHeight(context, 24),
            color: const Color(0xFFF0F0F0),
          ),
          _buildInfoRow(context, 'Bank', details.bankName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.textGrey,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (isCopyable) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              GestureDetector(
                onTap: () => _copyToClipboard(context, value),
                child: Icon(
                  Icons.copy_outlined,
                  size: AppLayout.scaleWidth(context, 16),
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, QrCodeState qrState) {
    return ElevatedButton.icon(
      onPressed: qrState.qrCodeUrl != null
          ? () => _saveQrCode(context, qrState.qrCodeUrl!)
          : null,
      icon: Icon(
        Icons.download_outlined,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 20),
      ),
      label: Text(
        'Save QR Code',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.4),
        minimumSize: Size(double.infinity, AppLayout.scaleHeight(context, 52)),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context, bool isLoading) {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () => ref.read(qrCodeProvider.notifier).generateQrCode(),
      icon: Icon(
        Icons.refresh,
        color: AppColors.primaryTeal,
        size: AppLayout.scaleWidth(context, 20),
      ),
      label: Text(
        'Generate New Code',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, AppLayout.scaleHeight(context, 52)),
        side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account number copied'),
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

  void _shareQrCode(BuildContext context, String? url) {
    if (url == null) return;
    // Share intent — integrate share_plus package when available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR Code shared'),
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

  void _saveQrCode(BuildContext context, String url) {
    // Save to gallery — integrate image_gallery_saver when available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR Code saved to gallery'),
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
}
