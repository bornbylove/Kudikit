import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/features/wallet/presentation/pages/addmoney/add_money_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/airtime/airtime_phone_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/cable_tv/cable_tv_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/data/data_phone_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/electricity/electricity_screen.dart';
import 'package:kudipay/presentation/cashout/cashout_menu_screen.dart';
import 'package:kudipay/presentation/request/request_menu_screen.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transfer_menu_screen.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';
import 'package:kudipay/provider/wallet/wallet_provider.dart';
import 'package:kudipay/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Model: one entry in the Bill & Utilities grid
// ---------------------------------------------------------------------------
class _BillItem {
  final String svgAsset;
  final String label;
  final Widget? navigateTo;

  const _BillItem({
    required this.svgAsset,
    required this.label,
    this.navigateTo,
  });
}

// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBalanceVisible = false;

  // -- Bill & Utilities: which card is currently selected (tapped) ----------
  // null  ? no selection yet (all outlined)
  // index ? the tapped card is filled, all others outlined
  int? _selectedBillIndex;

  // ---------------------------------------------------------------------------
  // SVG asset paths
  // ---------------------------------------------------------------------------
  static const _svgTransfer = 'assets/icons/transfer.svg';
  static const _svgRequest = 'assets/icons/request.svg';
  static const _svgCashOut = 'assets/icons/cashout.svg';
  static const _svgAirtime = 'assets/icons/airtime.svg';
  static const _svgData = 'assets/icons/data.svg';
  static const _svgTv = 'assets/icons/tv.svg';
  static const _svgElectricity = 'assets/icons/electricity.svg';
  static const _svgEducation = 'assets/icons/education.svg';
  static const _svgBetting = 'assets/icons/betting.svg';
  static const _svgSavings = 'assets/icons/saving.svg';
  static const _svgInternet = 'assets/icons/internet.svg';
  static const _svgHeadset = 'assets/icons/headset.svg';
  static const _svgBell = 'assets/icons/bell.svg';

  static const _teal = Color(0xFF069494);

  // ---------------------------------------------------------------------------
  // Bill items list — defined once, index-stable
  // ---------------------------------------------------------------------------
  static const List<_BillItem> _billItems = [
    _BillItem(
        svgAsset: _svgAirtime,
        label: 'Airtime',
        navigateTo: AirtimePhoneScreen()),
    _BillItem(svgAsset: _svgData, label: 'Data', navigateTo: DataPhoneScreen()),
    _BillItem(svgAsset: _svgTv, label: 'TV', navigateTo: CableTvScreen()),
    _BillItem(
        svgAsset: _svgElectricity,
        label: 'Electricity',
        navigateTo: ElectricityScreen()),
    _BillItem(svgAsset: _svgEducation, label: 'Education'),
    _BillItem(svgAsset: _svgBetting, label: 'Betting'),
    _BillItem(svgAsset: _svgSavings, label: 'Savings'),
    _BillItem(svgAsset: _svgInternet, label: 'Internet'),
  ];

  void _copyAccountNumber() {
    final wallet = ref.read(walletProvider);
    Clipboard.setData(
        ClipboardData(text: '${wallet.accountNumber} ${wallet.accountName}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account details copied!'),
        backgroundColor: _teal,
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

    final userInfo = ref.watch(userInfoProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    final tierState = ref.watch(tierProvider);
    final currentTierObject = tierState.getTierObject();
    final wallet = ref.watch(walletProvider);
    final isOnline = connectivityState.isConnected;

    final firstName = userInfo?.firstName ??
        (wallet.accountName.isNotEmpty
            ? wallet.accountName.split(' ').first.capitalize()
            : 'User');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // -- Offline banner -----------------------------------------------
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
                color: _teal,
                backgroundColor: Colors.white,
                strokeWidth: 0.5,
                displacement: 60,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Header ---------------------------------------------
                      Padding(
                        padding: AppLayout.pagePadding(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                                ),
                              ),
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 10)),
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
                                  SizedBox(
                                      width: AppLayout.scaleWidth(context, 6)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          AppLayout.scaleWidth(context, 8),
                                      vertical:
                                          AppLayout.scaleHeight(context, 3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: _teal.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppLayout.scaleWidth(context, 20)),
                                    ),
                                    child: Text(
                                      'Tier ${currentTierObject.tierNumber}',
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 11),
                                        color: _teal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 4)),
                            _buildHeaderIconButton(
                                context: context,
                                svgPath: _svgHeadset,
                                onTap: () {}),
                            SizedBox(width: AppLayout.scaleWidth(context, 8)),
                            _buildHeaderIconButton(
                                context: context,
                                svgPath: _svgBell,
                                onTap: () {}),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 8)),

                      // -- Balance card — flat solid teal, uniform radius -----
                      wallet.isLoading
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      AppLayout.scaleWidth(context, 16)),
                              child: const HomeBalanceCardShimmer(),
                            )
                          : Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal:
                                      AppLayout.scaleWidth(context, 16)),
                              padding: EdgeInsets.all(
                                  AppLayout.scaleWidth(context, 20)),
                              decoration: BoxDecoration(
                                color: _teal,
                                borderRadius: BorderRadius.circular(
                                    AppLayout.scaleWidth(context, 16)),
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
                                        borderRadius: BorderRadius.circular(
                                            AppLayout.scaleWidth(context, 16)),
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
                                                  color: _teal,
                                                  size: AppLayout.scaleWidth(
                                                      context, 14)),
                                              SizedBox(
                                                  width: AppLayout.scaleWidth(
                                                      context, 4)),
                                              Text('Add money',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppLayout.fontSize(
                                                            context, 12),
                                                    color: _teal,
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
                                              ? '?${wallet.formattedBalance}'
                                              : '? ••••••••••',
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
                                          size:
                                              AppLayout.scaleWidth(context, 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 6)),
                                  Text(
                                    !isOnline
                                        ? 'Offline — showing cached balance'
                                        : wallet.lastUpdated != null
                                            ? 'Last updated ${_timeAgo(wallet.lastUpdated!)}'
                                            : 'Last updated recently',
                                    style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 11),
                                        color: Colors.white
                                            .withValues(alpha: 0.7)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                      height:
                                          AppLayout.scaleHeight(context, 12)),
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
                                                  .withValues(alpha: 0.9),
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
                                                    .withValues(alpha: 0.5))),
                                        SizedBox(
                                            width: AppLayout.scaleWidth(
                                                context, 4)),
                                        Flexible(
                                          child: Text(
                                            userInfo != null
                                                ? '${userInfo.firstName} ${userInfo.lastName}'
                                                    .trim()
                                                : wallet.accountName,
                                            style: TextStyle(
                                                fontSize: AppLayout.fontSize(
                                                    context, 12),
                                                color: Colors.white
                                                    .withValues(alpha: 0.9)),
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
                                                .withValues(alpha: 0.7)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      SizedBox(height: AppLayout.scaleHeight(context, 20)),

                      // -- Quick Actions (Transfer / Request / Withdraw) ------
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16)),
                        child: Row(
                          children: [
                            _buildFilledActionPill(
                              context: context,
                              svgAsset: _svgTransfer,
                              label: 'Transfer',
                              onTap: () => _handleQuickAction(
                                  context, 'Transfer',
                                  navigateTo: const TransferMenuScreen()),
                              isEnabled: isOnline,
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 10)),
                            _buildOutlinedActionPill(
                              context: context,
                              svgAsset: _svgRequest,
                              label: 'Request',
                              onTap: () => _handleQuickAction(
                                  context, 'Request',
                                  navigateTo: const RequestMenuScreen()),
                              isEnabled: isOnline,
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 10)),
                            _buildOutlinedActionPill(
                              context: context,
                              svgAsset: _svgCashOut,
                              label: 'Withdraw',
                              onTap: () => _handleQuickAction(
                                  context, 'Withdraw',
                                  navigateTo: const CashoutMenuScreen()),
                              isEnabled: isOnline,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 24)),

                      // -- Bill & Utilities label -------------------------------
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

                      // -- Bill Services grid -----------------------------------
                      // Each card is independently togglable:
                      //   • tapped  ? filled teal bg + white icon/label
                      //   • others  ? white bg + dark icon/label + thin border
                      // Tapping the same card again de-selects it (back to outlined).
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16)),
                        child: Column(
                          children: [
                            // Row 1
                            Row(
                              children: List.generate(4, (i) {
                                return _billCardTile(
                                  context: context,
                                  index: i,
                                  isOnline: isOnline,
                                );
                              }).expand((w) sync* {
                                yield w;
                              }).toList()
                                ..insertSeparators(SizedBox(
                                    width: AppLayout.scaleWidth(context, 12))),
                            ),
                            SizedBox(
                                height: AppLayout.scaleHeight(context, 12)),
                            // Row 2
                            Row(
                              children: [
                                ...List.generate(3, (i) {
                                  return _billCardTile(
                                    context: context,
                                    index: i + 4,
                                    isOnline: isOnline,
                                  );
                                }).expand((w) sync* {
                                  yield w;
                                }).toList()
                                  ..insertSeparators(SizedBox(
                                      width:
                                          AppLayout.scaleWidth(context, 12))),
                                SizedBox(
                                    width: AppLayout.scaleWidth(context, 12)),
                                // Empty slot keeps 4-column grid alignment
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppLayout.scaleHeight(context, 24)),

                      // -- Recent Transactions header ----------------------------
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
                                  : () => ConnectivitySnackBar.showNoInternet(
                                      context),
                              child: Text('View All',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    color: isOnline ? _teal : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ),

                      if (!isOnline)
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16),
                            vertical: AppLayout.scaleHeight(context, 8),
                          ),
                          padding:
                              EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
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
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // -- Transaction list -------------------------------------
                      if (wallet.isLoading)
                        const HomeRecentTransactionsShimmer(itemCount: 3)
                      else ...[
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-?10,200.00',
                          isSuccess: true,
                        ),
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-?10,200.00',
                          isSuccess: true,
                        ),
                        _buildTransactionItem(
                          title: 'Transfer to POS Transfer - TEMI...',
                          date: 'Dec 20th, 10:39:25',
                          amount: '-?10,200.00',
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

  // ===========================================================================
  // Bill card tile — reads _selectedBillIndex to decide fill vs outline
  // ===========================================================================

  Widget _billCardTile({
    required BuildContext context,
    required int index,
    required bool isOnline,
  }) {
    final item = _billItems[index];
    final isSelected = _selectedBillIndex == index;
    final canTap = isOnline;

    return Expanded(
      child: Opacity(
        opacity: canTap ? 1.0 : 0.5,
        child: GestureDetector(
          onTap: canTap
              ? () {
                  setState(() {
                    // Tap same card ? deselect; tap different ? select it
                    _selectedBillIndex = isSelected ? null : index;
                  });
                  // Navigate only when selecting (not deselecting)
                  if (!isSelected) {
                    _handleQuickAction(context, item.label,
                        navigateTo: item.navigateTo);
                  }
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              vertical: AppLayout.scaleHeight(context, 14),
              horizontal: AppLayout.scaleWidth(context, 6),
            ),
            decoration: BoxDecoration(
              // ? Selected = filled teal; unselected = white with border
              color: isSelected ? _teal : Colors.white,
              border: Border.all(
                color: isSelected ? _teal : const Color(0xFFE9ECEF),
                width: 1.0,
              ),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  item.svgAsset,
                  width: AppLayout.scaleWidth(context, 22),
                  height: AppLayout.scaleWidth(context, 22),
                  colorFilter: ColorFilter.mode(
                    // ? Selected = white icon; unselected = dark navy
                    isSelected ? Colors.white : const Color(0xFF1A1A2E),
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 11),
                    fontWeight: FontWeight.w500,
                    // ? Selected = white label; unselected = dark navy
                    color: isSelected
                        ? Colors.white
                        : canTap
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey[400],
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
    );
  }

  // ===========================================================================
  // Header icon button
  // ===========================================================================

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
  // Filled teal pill (Transfer)
  // ===========================================================================

  Widget _buildFilledActionPill({
    required BuildContext context,
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 50)),
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 12)),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(svgAsset,
                    width: AppLayout.scaleWidth(context, 16),
                    height: AppLayout.scaleWidth(context, 16),
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                SizedBox(width: AppLayout.scaleWidth(context, 6)),
                Text(label,
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Outlined pill (Request / Withdraw)
  // ===========================================================================

  Widget _buildOutlinedActionPill({
    required BuildContext context,
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 50)),
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(svgAsset,
                    width: AppLayout.scaleWidth(context, 16),
                    height: AppLayout.scaleWidth(context, 16),
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF1A1A2E), BlendMode.srcIn)),
                SizedBox(width: AppLayout.scaleWidth(context, 6)),
                Text(label,
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E))),
              ],
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => navigateTo));
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
                    color: _teal, size: 28),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Text('$featureName Coming Soon',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'PolySans',
                  )),
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
                    backgroundColor: _teal,
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
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 8)),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            ),
            child: Icon(isSuccess ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSuccess ? _teal : Colors.red.shade700,
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
                      ? _teal.withValues(alpha: 0.1)
                      : Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
                ),
                child: Text(
                  isSuccess ? 'Successful' : 'Failed',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 9),
                    color: isSuccess ? _teal : Colors.red.shade700,
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

// ---------------------------------------------------------------------------
// List extension — inserts a separator widget between every item
// ---------------------------------------------------------------------------
extension _ListSeparatorExt<T extends Widget> on List<T> {
  void insertSeparators(Widget separator) {
    for (int i = length - 1; i > 0; i--) {
      insert(i, separator as T);
    }
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
