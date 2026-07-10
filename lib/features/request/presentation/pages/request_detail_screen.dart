import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/request/presentation/controllers/request_provider.dart';
import 'package:kudipay/features/request/domain/entities/request_model.dart';

// ─── Colours ───────────────────────────────────────────────────────────────────
const _teal = AppColors.primaryTeal;
const _bg = AppColors.backgroundScreen;
const _textDark = AppColors.textDark;
const _textGrey = AppColors.textGrey;
const _white = AppColors.white;

// ─── Request Detail Screen ─────────────────────────────────────────────────────
class RequestDetailScreen extends ConsumerStatefulWidget {
  final MoneyRequest request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  // Determine if the current user is the requester (sender) or the recipient
  // For now we treat the request based on its requesterId vs a mock userId
  bool get _isSender => widget.request.requesterId == 'current_user';

  MoneyRequest get _req => widget.request;

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  void _showPaymentOptions() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _PaymentOptionsDialog(
        onPayFull: () {
          Navigator.pop(context);
          _showConfirmPayment(_req.amount);
        },
        onPayPartial: () {
          Navigator.pop(context);
          _showPartialPaymentSheet();
        },
        onCounter: () {
          Navigator.pop(context);
          _showCounterOfferSheet();
        },
      ),
    );
  }

  void _showPartialPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PartialPaymentSheet(
        request: _req,
        onContinue: (amount) {
          Navigator.pop(context);
          _showConfirmPayment(amount);
        },
      ),
    );
  }

  void _showConfirmPayment(double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmPaymentSheet(
        request: _req,
        amount: amount,
        onPay: () async {
          Navigator.pop(context);
          await ref.read(requestProvider).payRequest(_req, amount);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showCounterOfferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CounterOfferSheet(request: _req),
    );
  }

  void _showDeclineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeclineSheet(
        onDecline: (reason) async {
          Navigator.pop(context);
          await ref.read(requestProvider).declineRequest(_req);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPaid = _req.status == RequestStatus.paid;
    final isExpired = _req.status == RequestStatus.expired;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomBar(context, isPaid, isExpired),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester info
            _buildRequesterRow(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Amount card (teal)
            _buildAmountCard(context, isPaid, isExpired),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Overdue banner (when applicable)
            if (_req.isOverdue && !isPaid && !isExpired)
              _buildOverdueBanner(context),

            // Request details
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildSectionTitle(context, 'Request Details'),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _buildDetailsCard(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Description
            _buildSectionTitle(context, 'Description'),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _buildDescriptionCard(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Payment history (paid only)
            if (isPaid) ...[
              _buildSectionTitle(context, 'Payment History'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildPaymentHistory(context),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
            ],
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
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

  // ── Requester row ──────────────────────────────────────────────────────────
  Widget _buildRequesterRow(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppLayout.scaleWidth(context, 26),
          backgroundColor: _avatarColor(_req),
          child: Text(
            _initials(_req.requesterName),
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.w700,
              fontSize: AppLayout.fontSize(context, 14),
            ),
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _req.requesterName,
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 2)),
            Text(
              _req.requesterPhone,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: _textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Amount card ────────────────────────────────────────────────────────────
  Widget _buildAmountCard(BuildContext context, bool isPaid, bool isExpired) {
    final label = isPaid
        ? 'Amount Paid'
        : isExpired
            ? 'Money Expired'
            : 'Money Requesting';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFF2E7D6E) : _teal,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: _white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          Text(
            '₦${NumberFormat('#,##0.00').format(isPaid ? (_req.paidAmount ?? _req.amount) : _req.amount)}',
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 28),
              fontWeight: FontWeight.w700,
              color: _white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Overdue banner ─────────────────────────────────────────────────────────
  Widget _buildOverdueBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 14),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade400,
              size: AppLayout.scaleWidth(context, 20)),
          SizedBox(width: AppLayout.scaleWidth(context, 10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overdue',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                'This request was due ${_req.daysOverdue} day${_req.daysOverdue != 1 ? 's' : ''} ago',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12),
                  color: Colors.red.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Details card ───────────────────────────────────────────────────────────
  Widget _buildDetailsCard(BuildContext context) {
    final dueText = _req.dueDate != null
        ? DateFormat('MMMM d, yyyy').format(_req.dueDate!)
        : '—';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 4),
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _detailRow(context, 'Category', _req.category),
          _divider(),
          _detailRow(
            context,
            'Due date',
            dueText,
            leadIcon: Icons.calendar_today_outlined,
          ),
          _divider(),
          _detailRow(
            context,
            'Privacy',
            _req.isPrivate ? 'Private' : 'Public',
            leadIcon: Icons.lock_outline,
          ),
          _divider(),
          _detailRow(context, 'Status', _req.statusText),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value,
      {IconData? leadIcon}) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 12)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: _textGrey,
              ),
            ),
          ),
          if (leadIcon != null) ...[
            Icon(leadIcon,
                size: AppLayout.scaleWidth(context, 13), color: _textGrey),
            SizedBox(width: AppLayout.scaleWidth(context, 4)),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF5F5F5));

  // ── Description card ───────────────────────────────────────────────────────
  Widget _buildDescriptionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _req.description ?? _req.reason ?? 'No description provided.',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: _textDark,
          height: 1.5,
        ),
      ),
    );
  }

  // ── Payment history ────────────────────────────────────────────────────────
  Widget _buildPaymentHistory(BuildContext context) {
    final paidAmt = _req.paidAmount ?? _req.amount;
    final paidDate = _req.paidAt ?? _req.createdAt;

    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.checkGreen,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Payment',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 3)),
                Text(
                  _timeAgo(paidDate),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₦${NumberFormat('#,##0.00').format(paidAmt)}',
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'PolySans',
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    );
  }

  // ── Bottom navigation bar ─────────────────────────────────────────────────
  Widget? _buildBottomBar(BuildContext context, bool isPaid, bool isExpired) {
    // Paid or expired — no actions
    if (isPaid || isExpired) return const SizedBox(height: 0);

    // Sender view — show "Send Reminder"
    if (_isSender) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.scaleWidth(context, 16),
            AppLayout.scaleHeight(context, 8),
            AppLayout.scaleWidth(context, 16),
            AppLayout.scaleHeight(context, 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reminder sent!'),
                      backgroundColor: _teal,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: AppLayout.scaleHeight(context, 16),
                        left: AppLayout.scaleWidth(context, 16),
                        right: AppLayout.scaleWidth(context, 16),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  minimumSize:
                      Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 30)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Send Reminder',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: _white,
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'We will send a reminder, requesting for payment',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12),
                  color: _textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Recipient view — "Pay Full Amount" + three action buttons
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 8),
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Pay Full Amount
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showConfirmPayment(_req.amount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      minimumSize: Size(0, AppLayout.scaleHeight(context, 52)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 30)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Pay Full Amount  ₦${NumberFormat('#,###').format(_req.amount)}',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: _white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 10)),
                // ••• menu button
                GestureDetector(
                  onTap: _showPaymentOptions,
                  child: Container(
                    width: AppLayout.scaleWidth(context, 48),
                    height: AppLayout.scaleHeight(context, 52),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 14)),
                    ),
                    child: Center(
                      child: Text(
                        '•••',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          color: _textDark,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),

            // Secondary: Pay partial | Counter | Decline
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    label: 'Pay partial',
                    onTap: _showPartialPaymentSheet,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                Expanded(
                  child: _SecondaryButton(
                    label: 'Counter',
                    onTap: _showCounterOfferSheet,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                Expanded(
                  child: _SecondaryButton(
                    label: 'Decline',
                    onTap: _showDeclineSheet,
                    textColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}

// ─── Secondary action button ───────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppLayout.scaleHeight(context, 44),
        decoration: BoxDecoration(
          color: _white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              fontWeight: FontWeight.w500,
              color: textColor ?? _textDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Payment Options Dialog (Image 7) ─────────────────────────────────────────
class _PaymentOptionsDialog extends StatelessWidget {
  final VoidCallback onPayFull;
  final VoidCallback onPayPartial;
  final VoidCallback onCounter;

  const _PaymentOptionsDialog({
    required this.onPayFull,
    required this.onPayPartial,
    required this.onCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Option',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: _textGrey,
                      size: AppLayout.scaleWidth(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            _OptionTile(label: 'Pay Full', onTap: onPayFull),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _OptionTile(label: 'Pay partial', onTap: onPayPartial),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _OptionTile(label: 'Counter', onTap: onCounter),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 14)),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Partial Payment Sheet (Image 11) ─────────────────────────────────────────
class _PartialPaymentSheet extends StatefulWidget {
  final MoneyRequest request;
  final void Function(double amount) onContinue;

  const _PartialPaymentSheet({required this.request, required this.onContinue});

  @override
  State<_PartialPaymentSheet> createState() => _PartialPaymentSheetState();
}

class _PartialPaymentSheetState extends State<_PartialPaymentSheet> {
  final _ctrl = TextEditingController();
  double _amount = 0;

  double get _remaining => widget.request.remainingAmount;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setPercent(double pct) {
    final val = (_remaining * pct).roundToDouble();
    setState(() {
      _amount = val;
      _ctrl.text = val.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.scaleWidth(context, 24)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Partial Payment',
                    style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: _textGrey,
                      size: AppLayout.scaleWidth(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text('Enter the amount you want to pay now',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: _textGrey)),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Text('Amount',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) =>
                  setState(() => _amount = double.tryParse(v) ?? 0),
              decoration: InputDecoration(
                prefixText: '₦ ',
                prefixStyle: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    color: _textGrey),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 10)),
                    borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 14),
                    vertical: AppLayout.scaleHeight(context, 14)),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 6)),
            Text(
              'Remaining:  ₦${NumberFormat('#,##0.00').format(_remaining)}',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12), color: _textGrey),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 14)),
            Row(
              children: [
                _percentChip(
                    context,
                    '25% (₦${NumberFormat('#,###').format(_remaining * 0.25)})',
                    0.25),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                _percentChip(
                    context,
                    '50% (₦${NumberFormat('#,###').format(_remaining * 0.50)})',
                    0.50),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                _percentChip(
                    context,
                    '75% (₦${NumberFormat('#,###').format(_remaining * 0.75)})',
                    0.75),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ElevatedButton(
              onPressed: _amount > 0 ? () => widget.onContinue(_amount) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                disabledBackgroundColor: _teal.withValues(alpha: 0.4),
                minimumSize:
                    Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 30))),
                elevation: 0,
              ),
              child: Text('Continue to Payment',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: _white)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _cancelButton(context),
          ],
        ),
      ),
    );
  }

  Widget _percentChip(BuildContext context, String label, double pct) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPercent(pct),
        child: Container(
          padding:
              EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 8)),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 11),
                    color: _textDark,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}

// ─── Confirm Payment Sheet (Image 12) ─────────────────────────────────────────
class _ConfirmPaymentSheet extends StatelessWidget {
  final MoneyRequest request;
  final double amount;
  final VoidCallback onPay;

  const _ConfirmPaymentSheet({
    required this.request,
    required this.amount,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppLayout.scaleWidth(context, 24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confirm Payment',
                    style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: _textGrey,
                      size: AppLayout.scaleWidth(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text('Review payment details',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: _textGrey)),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Details box
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              ),
              child: Column(
                children: [
                  _confirmRow(context, 'Paying to', request.requesterName),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  _confirmRow(context, 'Amount',
                      '₦${NumberFormat('#,##0.00').format(amount)}'),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  _confirmRow(
                      context, 'Reason', request.reason ?? request.category),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Note banner
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 14)),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FA),
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
              ),
              child: Text(
                'Note: Your payment will be processed immediately and ${request.requesterName} will be notified',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: const Color(0xFF2E6BA0),
                    height: 1.4),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                minimumSize:
                    Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 30))),
                elevation: 0,
              ),
              child: Text('Pay Now',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: _white)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _cancelButton(context),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13), color: _textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
                color: _textDark)),
      ],
    );
  }
}

// ─── Counter Offer Sheet (Image 10) ───────────────────────────────────────────
class _CounterOfferSheet extends StatefulWidget {
  final MoneyRequest request;
  const _CounterOfferSheet({required this.request});

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppLayout.scaleWidth(context, 24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Counter Offer',
                    style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: _textGrey,
                      size: AppLayout.scaleWidth(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text('Suggest a different amount',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: _textGrey)),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Text('Proposed Amount',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _sheetTextField(context, _amountCtrl, '₦',
                keyboardType: TextInputType.number),
            SizedBox(height: AppLayout.scaleHeight(context, 6)),
            Text(
              'Original:  ₦${NumberFormat('#,##0.00').format(widget.request.amount)}',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12), color: _textGrey),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text('Reason (optional)',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _sheetTextField(context, _reasonCtrl, 'Explain your counter reason',
                maxLines: 4),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                minimumSize:
                    Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 30))),
                elevation: 0,
              ),
              child: Text('Send Counter Offer',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: _white)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _cancelButton(context),
          ],
        ),
      ),
    );
  }
}

// ─── Decline Sheet (Image 9) ───────────────────────────────────────────────────
class _DeclineSheet extends StatefulWidget {
  final void Function(String? reason) onDecline;
  const _DeclineSheet({required this.onDecline});

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppLayout.scaleWidth(context, 24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(context),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Decline Request',
                    style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: _textGrey,
                      size: AppLayout.scaleWidth(context, 20)),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text('Let them know why you\'re declining',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: _textGrey)),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Text('Reason (optional)',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            _sheetTextField(context, _reasonCtrl, 'Add reason', maxLines: 4),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ElevatedButton(
              onPressed: () => widget.onDecline(
                  _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize:
                    Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 30))),
                elevation: 0,
              ),
              child: Text('Decline Request',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: _white)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            _cancelButton(context),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sheet helpers ──────────────────────────────────────────────────────

Widget _sheetHandle(BuildContext context) {
  return Center(
    child: Container(
      width: AppLayout.scaleWidth(context, 40),
      height: AppLayout.scaleHeight(context, 4),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

Widget _sheetTextField(
  BuildContext context,
  TextEditingController ctrl,
  String hint, {
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style:
        TextStyle(fontSize: AppLayout.fontSize(context, 14), color: _textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 13),
          color: AppColors.textLight),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          borderSide: const BorderSide(color: _teal, width: 1.5)),
      contentPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 14),
          vertical: AppLayout.scaleHeight(context, 14)),
    ),
  );
}

Widget _cancelButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: double.infinity,
      height: AppLayout.scaleHeight(context, 52),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          'Cancel',
          style: TextStyle(
              fontSize: AppLayout.fontSize(context, 15),
              fontWeight: FontWeight.w600,
              color: _textDark),
        ),
      ),
    ),
  );
}
