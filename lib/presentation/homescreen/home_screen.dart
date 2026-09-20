import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/formatting/widget/shimmer_widget.dart';
import 'package:kudipay/presentation/addmoney/add_money_screen.dart';
import 'package:kudipay/presentation/bill/airtime/airtime_phone_screen.dart';
import 'package:kudipay/presentation/bill/cable_tv/cable_tv_screen.dart';
import 'package:kudipay/presentation/bill/data/data_phone_screen.dart';
import 'package:kudipay/presentation/bill/electricity/electricity_screen.dart';
import 'package:kudipay/presentation/cashout/cashout_menu_screen.dart';
import 'package:kudipay/presentation/request/request_menu_screen.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transfer_menu_screen.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/provider/kyc/kyc_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';
import 'package:kudipay/provider/wallet/dashboard_provider.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart' show securitySettingsProvider;
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBalanceVisible = false;

  // ---------------------------------------------------------------------------
  // SVG asset paths — all icons live in assets/icons/
  // ---------------------------------------------------------------------------
  static const _svgTransfer    = 'assets/icons/transfer.svg';
  static const _svgRequest     = 'assets/icons/request.svg';
  static const _svgCashOut     = 'assets/icons/cashout.svg';
  static const _svgAirtime     = 'assets/icons/airtime.svg';
  static const _svgData        = 'assets/icons/data.svg';
  static const _svgTv          = 'assets/icons/tv.svg';
  static const _svgElectricity = 'assets/icons/electricity.svg';
  static const _svgEducation   = 'assets/icons/education.svg';
  static const _svgBetting     = 'assets/icons/betting.svg';
  static const _svgSavings     = 'assets/icons/saving.svg';

  // Header SVG icons
  static const _svgPerson  = 'assets/icons/person.svg';
  static const _svgHeadset = 'assets/icons/headset.svg';
  static const _svgBell    = 'assets/icons/bell.svg';

  void _copyAccountNumber() {
    final wallet = ref.read(walletProvider);
    Clipboard.setData(
        ClipboardData(text: '${wallet.accountNumber} ${wallet.accountName}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account details copied!'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        final wasConnected = previous?.value;
        if (wasConnected != null && wasConnected && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (wasConnected != null && !wasConnected && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });

    final userInfo         = ref.watch(userInfoProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    // SLICE 7 (P0-3): the header tier derives from the server-authoritative
    // GRANTED tier (0 = UNVERIFIED), never the local tierProvider.
    final user             = ref.watch(currentUserProvider);
    final grantedTier      = user?.grantedTierOrZero ?? 0;
    final wallet           = ref.watch(walletProvider);
    final isOnline         = connectivityState.isConnected;

    final firstName = userInfo?.firstName ??
        (wallet.accountName.isNotEmpty
            ? wallet.accountName.split(' ').first.capitalize()
            : 'User');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Offline banner ───────────────────────────────────────────────
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 8),
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                color: Colors.red.shade700,
                child: Row(
                  children: [
                    Icon(Icons.wifi_off,
                        color: Colors.white,
                        size: AppLayout.scaleWidth(context, 20)),
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                    Expanded(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: AppLayout.fontSize(context, 14)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(connectivityStateProvider.notifier)
                          .refresh(),
                      child: Text('Retry',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: AppLayout.fontSize(context, 14))),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(refreshProvider.notifier).refreshAll(),
                color: const Color(0xFF069494),
                backgroundColor: Colors.white,
                strokeWidth: 0.5,
                displacement: 60,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ─────────────────────────────────────────────
                      Padding(
                        padding: AppLayout.pagePadding(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // ── Avatar: SVG person icon in rounded mint box ──
                            Container(
                              width: AppLayout.scaleWidth(context, 44),
                              height: AppLayout.scaleWidth(context, 44),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5F3),
                                borderRadius: BorderRadius.circular(
                                    AppLayout.scaleWidth(context, 10)),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/img_placeholder.png',
                                  width: AppLayout.scaleWidth(context, 22),
                                  height: AppLayout.scaleWidth(context, 22),
                                  // colorFilter: const ColorFilter.mode(
                                  //   Color(0xFF069494),
                                  //   BlendMode.srcIn,
                                  // ),
                                ),
                              ),
                            ),

                            SizedBox(width: AppLayout.scaleWidth(context, 10)),

                            // ── Greeting + tier badge inline ─────────────────
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hi, $firstName',
                                    style: TextStyle(
                                      fontFamily: 'PolySans',
                                      fontSize: AppLayout.fontSize(context, 16),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF151717),
                                    ),
                                  ),
                                  SizedBox(width: AppLayout.scaleWidth(context, 6)),
                                  // Tier pill — inline, right of name
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppLayout.scaleWidth(context, 8),
                                      vertical: AppLayout.scaleHeight(context, 3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF069494).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppLayout.scaleWidth(context, 20)),
                                    ),
                                    child: Text(
                                      grantedTier > 0
                                          ? 'Tier $grantedTier'
                                          : 'UNVERIFIED',
                                      style: TextStyle(
                                        fontSize: AppLayout.fontSize(context, 11),
                                        color: const Color(0xFF069494),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: AppLayout.scaleWidth(context, 4)),

                            // ── Headset SVG icon button ──────────────────────
                            _buildHeaderIconButton(
                              context: context,
                              svgPath: _svgHeadset,
                              onTap: () {},
                            ),

                            SizedBox(width: AppLayout.scaleWidth(context, 8)),

                            // ── Bell SVG icon button ─────────────────────────
                            _buildHeaderIconButton(
                              context: context,
                              svgPath: _svgBell,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 8)),

                      // ── Balance card ─────────────────────────────────────────
                      wallet.isLoading
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppLayout.scaleWidth(context, 16)),
                              child: const HomeBalanceCardShimmer(),
                            )
                          : Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: AppLayout.scaleWidth(context, 16)),
                              padding: EdgeInsets.all(
                                  AppLayout.scaleWidth(context, 20)),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF069494),
                                    Color(0xFF339992),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppLayout.scaleWidth(context, 20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Available Balance',
                                          style: TextStyle(
                                              fontSize: AppLayout.fontSize(
                                                  context, 13),
                                              color: Colors.white70)),
                                      // Add Money button
                                      InkWell(
                                        onTap: () {
                                          if (isOnline) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AddMoneyScreen()),
                                            );
                                          } else {
                                            ConnectivitySnackBar.showNoInternet(
                                                context);
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppLayout.scaleWidth(
                                                context, 12),
                                            vertical: AppLayout.scaleHeight(
                                                context, 6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                AppLayout.scaleWidth(
                                                    context, 16)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add,
                                                  color: const Color(0xFF069494),
                                                  size: AppLayout.scaleWidth(
                                                      context, 14)),
                                              SizedBox(
                                                  width: AppLayout.scaleWidth(
                                                      context, 4)),
                                              Text('Add money',
                                                  style: TextStyle(
                                                    fontSize: AppLayout.fontSize(
                                                        context, 12),
                                                    color:
                                                        const Color(0xFF069494),
                                                    fontWeight: FontWeight.w500,
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 8)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _isBalanceVisible
                                              ? '₦${wallet.formattedBalance}'
                                              : '₦ ••••••••••',
                                          style: TextStyle(
                                            fontSize:
                                                AppLayout.fontSize(context, 32),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                          width: AppLayout.scaleWidth(
                                              context, 12)),
                                      InkWell(
                                        onTap: () => setState(() =>
                                            _isBalanceVisible =
                                                !_isBalanceVisible),
                                        child: Icon(
                                          _isBalanceVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white70,
                                          size: AppLayout.scaleWidth(
                                              context, 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 16)),
                                  Text(
                                    !isOnline
                                        ? 'Offline — showing cached balance'
                                        : wallet.lastUpdated != null
                                            ? 'Updated ${_timeAgo(wallet.lastUpdated!)}'
                                            : 'Last updated recently',
                                    style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 11),
                                        color:
                                            Colors.white.withOpacity(0.7)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // PRD §2.2.1 AC#6: "Pending Balance"
                                  // separate from "Available Balance" —
                                  // best-effort supplementary data, hidden
                                  // entirely if unavailable/still zero.
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final dashboardAsync =
                                          ref.watch(dashboardSummaryProvider);
                                      final pending = dashboardAsync
                                              .value?.pendingBalance ??
                                          0;
                                      if (pending <= 0 || !_isBalanceVisible) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            top: AppLayout.scaleHeight(
                                                context, 4)),
                                        child: Text(
                                          'Pending: ₦${NumberFormat('#,##0.00').format(pending)}',
                                          style: TextStyle(
                                              fontSize: AppLayout.fontSize(
                                                  context, 11),
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 8)),
                                  InkWell(
                                    onTap: _copyAccountNumber,
                                    child: Row(
                                      children: [
                                        Text(
                                          wallet.accountNumber,
                                          style: TextStyle(
                                              fontSize: AppLayout.fontSize(
                                                  context, 12),
                                              color: Colors.white
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(
                                            width: AppLayout.scaleWidth(
                                                context, 4)),
                                        Text('|',
                                            style: TextStyle(
                                                fontSize: AppLayout.fontSize(
                                                    context, 12),
                                                color: Colors.white
                                                    .withOpacity(0.5))),
                                        SizedBox(
                                            width: AppLayout.scaleWidth(
                                                context, 4)),
                                        Flexible(
                                          child: Text(
                                            userInfo != null
                                                ? '${userInfo.firstName} ${userInfo.lastName ?? ''}'
                                                    .trim()
                                                : wallet.accountName,
                                            style: TextStyle(
                                                fontSize: AppLayout.fontSize(
                                                    context, 12),
                                                color: Colors.white
                                                    .withOpacity(0.9)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                            width: AppLayout.scaleWidth(
                                                context, 8)),
                                        Icon(Icons.copy,
                                            size: AppLayout.scaleWidth(
                                                context, 12),
                                            color: Colors.white
                                                .withOpacity(0.7)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      SizedBox(height: AppLayout.scaleHeight(context, 20)),

                      // ── Quick Stats + Security indicator (PRD §2.2.1 §6/§7) ───
                      const _QuickStatsCard(),

                      SizedBox(height: AppLayout.scaleHeight(context, 20)),

                      // ── Quick Actions row (Transfer / Request / Cash out) ─────
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppLayout.scaleWidth(context, 16),
                          vertical: AppLayout.scaleWidth(context, 12),
                        ),
                        child: Row(
                          children: [
                            _buildActionCard(
                              svgAsset: _svgTransfer,
                              label: 'Transfer',
                              onTap: () => _handleQuickAction(
                                  context, 'Transfer',
                                  navigateTo: const TransferMenuScreen()),
                              isEnabled: isOnline,
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 12)),
                            _buildActionCard(
                              svgAsset: _svgRequest,
                              label: 'Request',
                              onTap: () => _handleQuickAction(
                                  context, 'Request',
                                  navigateTo: const RequestMenuScreen()),
                              isEnabled: isOnline,
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 12)),
                            _buildActionCard(
                              svgAsset: _svgCashOut,
                              label: 'Cash out',
                              onTap: () => _handleQuickAction(
                                  context, 'Cash out',
                                  navigateTo: const CashoutMenuScreen()),
                              isEnabled: isOnline,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 24)),

                      // ── Bill & Utilities label ───────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16)),
                        child: Text(
                          'Bill & Utilities',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 12)),

                      // ── Bill Services grid ───────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildActionCard(
                                  svgAsset: _svgAirtime,
                                  label: 'Airtime',
                                  onTap: () => _handleQuickAction(
                                      context, 'Airtime',
                                      navigateTo: const AirtimePhoneScreen()),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                _buildActionCard(
                                  svgAsset: _svgData,
                                  label: 'Data',
                                  onTap: () => _handleQuickAction(
                                      context, 'Data',
                                      navigateTo: const DataPhoneScreen()),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                _buildActionCard(
                                  svgAsset: _svgTv,
                                  label: 'TV',
                                  onTap: () => _handleQuickAction(context, 'Tv',
                                      navigateTo: const CableTvScreen()),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                _buildActionCard(
                                  svgAsset: _svgElectricity,
                                  label: 'Electricity',
                                  onTap: () => _handleQuickAction(
                                      context, 'Electricity',
                                      navigateTo: const ElectricityScreen()),
                                  isEnabled: isOnline,
                                ),
                              ],
                            ),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 12)),
                            Row(
                              children: [
                                _buildActionCard(
                                  svgAsset: _svgEducation,
                                  label: 'Education',
                                  onTap: () =>
                                      _handleQuickAction(context, 'Education'),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                _buildActionCard(
                                  svgAsset: _svgBetting,
                                  label: 'Betting',
                                  onTap: () =>
                                      _handleQuickAction(context, 'Betting'),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                _buildActionCard(
                                  svgAsset: _svgSavings,
                                  label: 'Savings',
                                  onTap: () =>
                                      _handleQuickAction(context, 'Savings'),
                                  isEnabled: isOnline,
                                ),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 24)),

                      // ── Recent Transactions header ────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Transactions',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                )),
                            TextButton(
                              onPressed: isOnline
                                  ? () {}
                                  : () =>
                                      ConnectivitySnackBar.showNoInternet(
                                          context),
                              child: Text('View All',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    color: isOnline
                                        ? const Color(0xFF069494)
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ),

                      // Offline cached-data notice
                      if (!isOnline)
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16),
                            vertical: AppLayout.scaleHeight(context, 8),
                          ),
                          padding: EdgeInsets.all(
                              AppLayout.scaleWidth(context, 12)),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: AppLayout.scaleWidth(context, 20)),
                              SizedBox(
                                  width: AppLayout.scaleWidth(context, 12)),
                              Expanded(
                                child: Text(
                                  'You\'re viewing cached transactions. Connect to internet for latest updates.',
                                  style: TextStyle(
                                      fontSize:
                                          AppLayout.fontSize(context, 12),
                                      color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Transaction list ─────────────────────────────────────
                      if (wallet.isLoading)
                        const HomeRecentTransactionsShimmer(itemCount: 3)
                      else ...[
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-₦10,200.00',
                          isSuccess: true,
                        ),
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-₦10,200.00',
                          isSuccess: true,
                        ),
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-₦10,200.00',
                          isSuccess: false,
                        ),
                      ],

                      SizedBox(height: AppLayout.scaleHeight(context, 100)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small icon button used in the header ──────────────────────────────────
  Widget _buildHeaderIconButton({
    required BuildContext context,
    required String svgPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppLayout.scaleWidth(context, 36),
        height: AppLayout.scaleWidth(context, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
        ),
        child: Center(
          child: SvgPicture.asset(
            svgPath,
            width: AppLayout.scaleWidth(context, 18),
            height: AppLayout.scaleWidth(context, 18),
            colorFilter: const ColorFilter.mode(
              Color(0xFF6B7280),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // _buildActionCard
  // ===========================================================================
  Widget _buildActionCard({
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final iconColor = isEnabled
        ? AppColors.primaryTeal
        : const Color(0xFFCBD5E1);

    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: AppLayout.scaleHeight(context, 12),
              horizontal: AppLayout.scaleWidth(context, 12),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textGrey, width: 0.35),
              color: AppColors.backgroundScreen,
              borderRadius: BorderRadius.circular(
                AppLayout.scaleWidth(context, 12),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    svgAsset,
                    width: AppLayout.scaleWidth(context, 17),
                    height: AppLayout.scaleWidth(context, 17),
                    colorFilter:
                        ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 10),
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? Colors.black87 : Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Navigation helpers
  // ===========================================================================

  void _handleQuickAction(
    BuildContext context,
    String actionName, {
    Widget? navigateTo,
  }) {
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.wifi_off, size: 48, color: Colors.red.shade700),
          title: const Text('No Internet Connection'),
          content: Text(
            'You need an internet connection to use $actionName. '
            'Please check your connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(connectivityStateProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return;
    }

    if (navigateTo != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => navigateTo));
    } else {
      _showComingSoon(context, actionName);
    }
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 24),
            vertical: AppLayout.scaleHeight(context, 28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.rocket_launch_outlined,
                    color: Color(0xFF069494), size: 28),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Text(
                '$featureName Coming Soon',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'PolySans',
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'We\'re working hard to bring you this feature. '
                'Stay tuned for updates!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: const Color(0xFF9E9E9E),
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text('Got it',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Transaction row
  // ===========================================================================

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isSuccess,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 4),
      ),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.backgroundScreen,
        borderRadius:
            BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF069494).withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            ),
            child: Icon(
                isSuccess ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSuccess
                    ? const Color(0xFF069494)
                    : Colors.red.shade700,
                size: AppLayout.scaleWidth(context, 16)),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: AppLayout.scaleHeight(context, 2)),
                Text(date,
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 11),
                        color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),
              SizedBox(height: AppLayout.scaleHeight(context, 2)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 8),
                  vertical: AppLayout.scaleHeight(context, 2),
                ),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF069494).withOpacity(0.1)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 8)),
                ),
                child: Text(
                  isSuccess ? 'Successful' : 'Failed',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 9),
                    color: isSuccess
                        ? const Color(0xFF069494)
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}

// =============================================================================
// _QuickStatsCard — PRD §2.2.1
//   §6 Quick Stats: "Monthly inflow/outflow, Rewards earned this month,
//      Savings goal progress (if set)"
//   §7 Security Indicators: "Last login timestamp and device"
// Backed by GET /dashboard (quickStats) and GET /security/settings
// (currentSession) — both best-effort: the whole card hides itself rather
// than block the dashboard if either call fails or is still loading.
//
// Coverage note: the backend's quickStats only exposes todaySpent/
// todayReceived/monthlySpent/totalTransactions — there is no monthly
// *inflow* (received) field, and no savings-goal concept anywhere in the
// three backend services audited for this app, so those two PRD bullets
// are not renderable yet without backend additions. Rewards-this-month
// would need summing /rewards/history client-side by date, which needs
// pagination handling the rewards feature doesn't have wired up yet
// either — left out rather than half-built silently.
// =============================================================================
class _QuickStatsCard extends ConsumerWidget {
  const _QuickStatsCard();

  String _money(double v) => '₦${NumberFormat('#,##0').format(v)}';

  String _lastActive(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    return DateFormat('MMM d, h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final securityAsync = ref.watch(securitySettingsProvider);

    final stats = dashboardAsync.value?.quickStats;
    final security = securityAsync.value;

    if (stats == null && security == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats != null)
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Spent today',
                    value: _money(stats.todaySpent),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Received today',
                    value: _money(stats.todayReceived),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Spent this month',
                    value: _money(stats.monthlySpent),
                  ),
                ),
              ],
            ),
          if (stats != null && security?.lastActive != null)
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 12)),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
          if (security?.lastActive != null)
            Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: AppLayout.scaleWidth(context, 14),
                    color: Colors.grey[500]),
                SizedBox(width: AppLayout.scaleWidth(context, 6)),
                Expanded(
                  child: Text(
                    'Last active ${_lastActive(security!.lastActive)}'
                    '${security.currentDevice != null ? ' · ${security.currentDevice}' : ''}',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 11),
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 2)),
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 10),
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}