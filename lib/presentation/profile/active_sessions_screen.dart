// lib/presentation/profile/active_sessions_screen.dart
// PRD §2.3.2: "Device Management... Active Sessions: View and revoke in
// security settings." Backed by GET/DELETE /security/sessions* — see
// sessions_provider.dart / security_services.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/auth/sessions_provider.dart';
import 'package:kudipay/services/security_services.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionsProvider);

    ref.listen<SessionsState>(sessionsProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        title: Text(
          'Active Sessions',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: AppLayout.fontSize(context, 17),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sessionsProvider.notifier).load(),
        child: state.isLoading && state.sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SessionsState state) {
    if (state.sessions.isEmpty && !state.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 120)),
          Icon(Icons.devices_other, size: 56, color: Colors.grey[400]),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Center(
            child: Text(
              state.error ?? 'No active sessions found',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      children: [
        Text(
          'These are the devices currently signed in to your Kudikit account. '
          'If you don\'t recognize one, revoke it and change your passcode.',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        ...state.sessions.map((s) => _SessionCard(
              session: s,
              revoking: state.revokingId == s.sessionId,
              onRevoke: () =>
                  ref.read(sessionsProvider.notifier).revoke(s.sessionId),
            )),
        if (state.sessions.length > 1) ...[
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 48),
            child: OutlinedButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(sessionsProvider.notifier).revokeAllOthers(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
                side: const BorderSide(color: Color(0xFFD32F2F)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
                ),
              ),
              child: const Text('Log out of all other devices',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        SizedBox(height: AppLayout.scaleHeight(context, 40)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ActiveSession session;
  final bool revoking;
  final VoidCallback onRevoke;

  const _SessionCard({
    required this.session,
    required this.revoking,
    required this.onRevoke,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 44),
            height: AppLayout.scaleWidth(context, 44),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smartphone,
                color: AppColors.primaryTeal,
                size: AppLayout.scaleWidth(context, 22)),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceInfo,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                if (session.ipAddress.isNotEmpty)
                  Text(
                    session.ipAddress,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey,
                    ),
                  ),
                SizedBox(height: AppLayout.scaleHeight(context, 2)),
                Text(
                  'Last active: ${_formatTime(session.lastActivity)}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          revoking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                  tooltip: 'Revoke this session',
                  onPressed: onRevoke,
                ),
        ],
      ),
    );
  }
}
