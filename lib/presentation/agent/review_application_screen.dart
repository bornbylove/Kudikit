// -----------------------------------------------------------------------------
// Review Application Screen
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/core/utils/formatters.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

import 'agent_registration_flow.dart'
    show KudiCircularProgress, KudiPrimaryButton, KudiCard;

class ReviewApplicationScreen extends ConsumerWidget {
  const ReviewApplicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentRegistrationProvider);
    final notifier = ref.read(agentRegistrationProvider.notifier);
    final app = state.application;

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Agent Information',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding:
                EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: KudiCircularProgress(progress: state.progressPercent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Application',
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text(
              'Please confirm all details are correct before submitting.',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: AppColors.textGrey),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Business Details
            _ReviewSection(
              title: 'Business Details',
              rows: [
                _ReviewRow(
                    label: 'Business Name',
                   value: app.businessName,
                    onEdit: () => notifier.goToStep(0)),
                _ReviewRow(
                    label: 'Business Type',
                    value: app.businessType?.label ?? '—',
                    onEdit: () => notifier.goToStep(0)),
                _ReviewRow(
                    label: 'Description',
                    value: app.businessDescription.isEmpty
                        ? '—'
                        : app.businessDescription,
                    onEdit: () => notifier.goToStep(0),
                    isLast: true),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Location
            _ReviewSection(
              title: 'Location',
              rows: [
                _ReviewRow(
                    label: 'Address',
                    value: app.businessAddress,
                    onEdit: () => notifier.goToStep(1)),
                _ReviewRow(
                    label: 'Photo',
                    value: app.storefrontPhotoUrl.isEmpty
                        ? 'Not uploaded'
                        : 'Uploaded',
                    onEdit: () => notifier.goToStep(1),
                    isLast: true),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Operating Setup
            _ReviewSection(
              title: 'Operating Setup',
              rows: [
                _ReviewRow(
                    label: 'Days',
                    value: _formatDays(app.operatingDays),
                    onEdit: () => notifier.goToStep(2)),
                _ReviewRow(
                    label: 'Hours',
                    value: '${app.openingTime} – ${app.closingTime}',
                    onEdit: () => notifier.goToStep(2)),
                _ReviewRow(
                    label: 'Cash Float',
                    value:
                        '?${TransactionFormatter.formatAmount(app.cashFloat)}',
                    onEdit: () => notifier.goToStep(2)),
                _ReviewRow(
                    label: 'Transaction Limit',
                    value:
                        '?${TransactionFormatter.formatAmount(app.maxPerTransaction)}',
                    onEdit: () => notifier.goToStep(2)),
                _ReviewRow(
                    label: 'Commission Rate',
                    value: '${app.commissionRate}%',
                    onEdit: () => notifier.goToStep(2),
                    isLast: true),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Bank Account
            _ReviewSection(
              title: 'Bank Account',
              rows: [
                _ReviewRow(
                    label: 'Bank',
                    value: app.bankName,
                    onEdit: () => notifier.goToStep(3)),
                _ReviewRow(
                    label: 'Account Number',
                    value: _maskAccount(app.accountNumber),
                    onEdit: () => notifier.goToStep(3),
                    isLast: true),
              ],
            ),

            if (state.errorMessage != null) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                ),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: AppLayout.fontSize(context, 13),
                  ),
                ),
              ),
            ],
            SizedBox(height: AppLayout.scaleHeight(context, 100)),
          ],
        ),
      ),
      bottomNavigationBar: KudiPrimaryButton(
        label: 'Continue',
        isLoading: state.isSubmitting,
        onPressed: state.isSubmitting
            ? null
            : () async {
                // TODO: replace 'current_user_id' with real auth provider value
                await notifier.submitApplication(userId: 'current_user_id');
                if (ref.read(agentRegistrationProvider).isSubmitted &&
                    context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageTransition(const ApplicationSubmittedScreen()),
                  );
                }
              },
      ),
    );
  }

  String _formatDays(List<String> days) {
    if (days.isEmpty) return '—';
    if (days.length >= 7) return 'Daily';
    return days.join(' – ');
  }

  String _maskAccount(String account) {
    if (account.length < 6) return account;
    return '${account.substring(0, 3)}****${account.substring(account.length - 3)}';
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _ReviewSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: AppLayout.scaleWidth(context, 12),
                offset: Offset(0, AppLayout.scaleHeight(context, 4)),
              ),
            ],
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool isLast;

  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 14),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 11),
                            color: AppColors.textLight)),
                    SizedBox(height: AppLayout.scaleHeight(context, 3)),
                    Text(value,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Edit',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        )),
                    SizedBox(width: AppLayout.scaleWidth(context, 2)),
                    Icon(Icons.arrow_forward_ios,
                        size: AppLayout.scaleWidth(context, 11),
                        color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: AppLayout.scaleWidth(context, 14),
            endIndent: AppLayout.scaleWidth(context, 14),
            color: AppColors.divider,
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Application Submitted Screen
// -----------------------------------------------------------------------------

class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Agent Information',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding:
                EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: const KudiCircularProgress(progress: 1.0),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 64),
                height: AppLayout.scaleWidth(context, 64),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    color: AppColors.white,
                    size: AppLayout.scaleWidth(context, 32)),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
              Text(
                'Application Submitted!',
                style: TextStyle(
                  fontFamily: 'PolySans',
                  fontSize: AppLayout.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                "Your agent application is now under review. We'll notify you once it's approved.",
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KudiPrimaryButton(
        label: 'Done',
        onPressed: () {
          ref.read(agentRegistrationProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Agent Dashboard Screen
// -----------------------------------------------------------------------------

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentDashboardProvider);
    final notifier = ref.read(agentDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hello, Welcome',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: AppColors.textGrey),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 2)),
            Text(
              "Michael's Store",
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 22),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Availability toggle
            KudiCard(
              child: Row(
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 10),
                    height: AppLayout.scaleWidth(context, 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isAvailable
                          ? AppColors.checkGreen
                          : AppColors.textGrey,
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available',
                          style: TextStyle(
                            fontFamily: 'PolySans',
                            fontSize: AppLayout.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 2)),
                        Text(
                          state.isAvailable
                              ? 'Accepting withdrawal requests'
                              : 'Not accepting requests',
                          style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.isAvailable,
                    onChanged: (_) => notifier.toggleAvailability(),
                    activeThumbColor: AppColors.primaryTeal,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Today's Earning header
            Text(
              "Today's Earning",
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Stat cards — flexible row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Commission',
                    value:
                        '?${TransactionFormatter.formatAmount(state.todayCommission)}',
                    sub: '? 12% vs yesterday',
                    subColor: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 12)),
                Expanded(
                  child: _StatCard(
                    label: 'Transactions',
                    value: '${state.todayTransactions}',
                    sub:
                        '?${TransactionFormatter.formatAmount(state.totalAmount)} total',
                    subColor: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Mini stats
            KudiCard(
              child: Row(
                children: [
                  _MiniStat(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: AppColors.primaryTeal.withValues(alpha: 0.1),
                    iconColor: AppColors.primaryTeal,
                  ),
                  _MiniStat(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: Colors.orange.withValues(alpha: 0.1),
                    iconColor: Colors.orange,
                  ),
                  _MiniStat(
                    icon: Icons.show_chart_rounded,
                    label: 'Cash Out',
                    value: '12',
                    iconBg: Colors.blue.withValues(alpha: 0.1),
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Pending requests
            Text(
              "Today's Earning",
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            if (state.pendingRequests.isEmpty)
              KudiCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 24)),
                    child: Text(
                      'No pending requests',
                      style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: AppLayout.fontSize(context, 13)),
                    ),
                  ),
                ),
              )
            else
              ...state.pendingRequests.map((req) => Padding(
                    padding: EdgeInsets.only(
                        bottom: AppLayout.scaleHeight(context, 12)),
                    child: _RequestCard(
                      request: req,
                      onAccept: () => notifier.acceptRequest(req),
                    ),
                  )),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),
          ],
        ),
      ),
    );
  }
}

// -- Dashboard sub-widgets -----------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color subColor;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 12),
            offset: Offset(0, AppLayout.scaleHeight(context, 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 12),
                  color: AppColors.textGrey)),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          Text(value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 22),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
                fontFamily: 'PolySans',
              )),
          SizedBox(height: AppLayout.scaleHeight(context, 4)),
          Text(sub,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 11),
                  color: subColor)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.iconBg,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 40),
            height: AppLayout.scaleWidth(context, 40),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
            ),
            child: Icon(icon,
                color: iconColor,
                size: AppLayout.scaleWidth(context, 20)),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          Text(label,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 11),
                  color: AppColors.textGrey)),
          SizedBox(height: AppLayout.scaleHeight(context, 2)),
          Text(value,
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              )),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;

  const _RequestCard({required this.request, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return KudiCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'] ?? '',
                      style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 4)),
                    Text(
                      '?${TransactionFormatter.formatAmount(request['amount'] ?? 0)}',
                      style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 6)),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: AppLayout.scaleWidth(context, 12),
                            color: AppColors.textGrey),
                        SizedBox(width: AppLayout.scaleWidth(context, 3)),
                        Text(request['distance'] ?? '',
                            style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 11),
                                color: AppColors.textGrey)),
                        SizedBox(width: AppLayout.scaleWidth(context, 10)),
                        Icon(Icons.access_time,
                            size: AppLayout.scaleWidth(context, 12),
                            color: AppColors.textGrey),
                        SizedBox(width: AppLayout.scaleWidth(context, 3)),
                        Text(request['timeAgo'] ?? '',
                            style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 11),
                                color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+?${TransactionFormatter.formatAmount(request['commission'] ?? 0)}',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text('Commission',
                      style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 11),
                          color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 14)),
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 44),
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 12)),
                ),
              ),
              child: Text(
                'Accept Request',
                style: AppTextStyles.responsiveButtonText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Export step3 and step4 from this file so they can be imported by the flow