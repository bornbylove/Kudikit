import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/presentation/request/request_detail_screen.dart';
import 'package:kudipay/presentation/request/request_money_main_screen.dart';
import 'package:kudipay/provider/request/request_provider.dart';
import '../../model/request/request_model.dart';

// --- Colour helpers ------------------------------------------------------------
const _teal = AppColors.primaryTeal;
const _bg = AppColors.backgroundScreen;
const _textDark = AppColors.textDark;
const _textGrey = AppColors.textGrey;
const _white = AppColors.white;

// --- My Requests Screen --------------------------------------------------------
class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab order: Received | Sent | Paid | Expired
  static const _tabs = ['Received', 'Sent', 'Paid', 'Expired'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(requestProvider).loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(requestProvider);

    // Badge counts
    final receivedCount = provider.receivedRequests.length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildNewRequestButton(context),
      body: provider.isLoading
          ? const SafeArea(child: ProfileShimmer())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 16),
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -- Summary row ------------------------------------------
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppLayout.scaleWidth(context, 12),
                        AppLayout.scaleHeight(context, 12),
                        AppLayout.scaleWidth(context, 12),
                        AppLayout.scaleHeight(context, 4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'To Receive',
                              amount: provider.totalToReceive,
                              bgColor: const Color(0xFFEDF7F1),
                            ),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 10)),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Waiting On',
                              amount: provider.totalWaitingOn,
                              bgColor: const Color(0xFFEBF3FA),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -- Tab bar ----------------------------------------------
                    _buildTabBar(context, receivedCount),

                    // -- Tab views (fixed height, no nested scroll) -----------
                    SizedBox(
                      height: AppLayout.scaleHeight(context, 300),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _RequestListView(
                            requests: provider.receivedRequests,
                            emptyLabel: 'No received requests',
                          ),
                          _RequestListView(
                            requests: provider.sentRequests,
                            emptyLabel: 'No sent requests',
                          ),
                          _RequestListView(
                            requests: [
                              ...provider.receivedRequests
                                  .where((r) => r.status == RequestStatus.paid),
                              ...provider.sentRequests
                                  .where((r) => r.status == RequestStatus.paid),
                            ],
                            emptyLabel: 'No paid requests',
                          ),
                          _RequestListView(
                            requests: [
                              ...provider.receivedRequests.where(
                                  (r) => r.status == RequestStatus.expired),
                              ...provider.sentRequests.where(
                                  (r) => r.status == RequestStatus.expired),
                            ],
                            emptyLabel: 'No expired requests',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: _textDark, size: AppLayout.scaleWidth(context, 18)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'My Request',
        style: TextStyle(
          fontFamily: 'PolySans',
          color: _textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTabBar(BuildContext context, int receivedCount) {
    return TabBar(
      controller: _tabController,
      isScrollable: false,
      labelStyle: TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        fontWeight: FontWeight.w400,
      ),
      labelColor: _teal,
      unselectedLabelColor: _textGrey,
      indicatorColor: _teal,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 2,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Received'),
              if (receivedCount > 0) ...[
                SizedBox(width: AppLayout.scaleWidth(context, 4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 5),
                    vertical: AppLayout.scaleHeight(context, 1),
                  ),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 10)),
                  ),
                  child: Text(
                    '$receivedCount',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 10),
                      color: _white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Tab(text: 'Sent'),
        const Tab(text: 'Paid'),
        const Tab(text: 'Expired'),
      ],
    );
  }

  Widget _buildNewRequestButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 8),
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 16),
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestMoneyMainScreen()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            minimumSize:
                Size(double.infinity, AppLayout.scaleHeight(context, 52)),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
            ),
            elevation: 0,
          ),
          child: Text(
            'New request',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: _white,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Summary stat card ---------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color bgColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 14),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 4)),
          Text(
            '?${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tab list view -------------------------------------------------------------
class _RequestListView extends ConsumerWidget {
  final List<MoneyRequest> requests;
  final String emptyLabel;

  const _RequestListView({
    required this.requests,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: _textGrey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 12),
        vertical: AppLayout.scaleHeight(context, 8),
      ),
      itemCount: requests.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: const Color(0xFFF0F0F0),
        indent: AppLayout.scaleWidth(context, 52),
      ),
      itemBuilder: (context, i) {
        final req = requests[i];
        return _RequestRow(
          request: req,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(request: req),
            ),
          ),
        );
      },
    );
  }
}

// --- Individual request row ----------------------------------------------------
class _RequestRow extends StatelessWidget {
  final MoneyRequest request;
  final VoidCallback onTap;

  const _RequestRow({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(request.createdAt);
    final dueMonth = request.dueDate != null
        ? DateFormat('MMM').format(request.dueDate!)
        : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 10),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: AppLayout.scaleWidth(context, 20),
              backgroundColor: _avatarColor(request),
              child: Text(
                _initials(request.requesterName),
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppLayout.fontSize(context, 12),
                ),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 10)),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text(
                    '${request.category}  $timeAgo',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 11),
                      color: _textGrey,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            _StatusBadge(request: request),
            SizedBox(width: AppLayout.scaleWidth(context, 8)),

            // Amount + due month
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  request.status == RequestStatus.expired ||
                          request.status == RequestStatus.declined
                      ? '?${NumberFormat('#,###.00').format(request.amount)}'
                      : request.status == RequestStatus.pending
                          ? '-?${NumberFormat('#,###.00').format(request.amount)}'
                          : '?${NumberFormat('#,###.00').format(request.amount)}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                if (dueMonth.isNotEmpty) ...[
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: AppLayout.scaleWidth(context, 10),
                          color: _textGrey),
                      SizedBox(width: AppLayout.scaleWidth(context, 2)),
                      Text(
                        dueMonth,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 10),
                          color: _textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  Color _avatarColor(MoneyRequest r) {
    const colors = [
      AppColors.avatarTeal,
      AppColors.avatarRed,
      AppColors.avatarOrange,
      AppColors.avatarDark,
      AppColors.avatarBlue,
    ];
    return colors[r.id.hashCode.abs() % colors.length];
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0)
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0)
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0)
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }
}

// --- Status badge --------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final MoneyRequest request;

  const _StatusBadge({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = request.statusColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 8),
        vertical: AppLayout.scaleHeight(context, 3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 6)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        request.statusText,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 11),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
