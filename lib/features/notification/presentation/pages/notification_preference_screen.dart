import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/features/notification/presentation/pages/notification_category_screen.dart';
import 'package:kudipay/features/notification/presentation/pages/notification_preferences.dart';
import 'package:kudipay/provider/provider.dart';

class NotificationPreferenceScreen extends ConsumerWidget {
  const NotificationPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Preference',
          style: TextStyle(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: preferencesState.when(
          // Fix 2: typed as NotificationPreferences instead of dynamic
          data: (preferences) => _buildContent(context, preferences),
          // Fix 1: shimmer instead of spinner
          loading: () => const NotificationPrefsShimmer(),
          // Fix 3: proper error state with icon, message, and retry button
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: AppLayout.scaleWidth(context, 64),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  Text(
                    'Unable to load preferences',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  Text(
                    'Your notification settings could not be loaded. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 24)),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(notificationPreferencesProvider.notifier)
                        .loadPreferences(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 32)),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 32),
                        vertical: AppLayout.scaleHeight(context, 12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fix 2: explicit NotificationPreferences type instead of dynamic
  Widget _buildContent(
      BuildContext context, NotificationPreferences preferences) {
    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildCategoryTile(
                  context,
                  icon: Icons.payment,
                  title: 'Transaction',
                  subtitle: 'Payments, deposits, balance alerts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationCategoryScreen(
                          category: NotificationCategory.transaction,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Bills & Reminders',
                  subtitle: 'Upcoming bills and due dates',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationCategoryScreen(
                          category: NotificationCategory.bills,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.card_giftcard,
                  title: 'Reward & Offers',
                  subtitle: 'Cashback, rewards, and promotions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationCategoryScreen(
                          category: NotificationCategory.rewards,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'App updates & Tips',
                  subtitle: 'New features, announcement, and tutorials',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationCategoryScreen(
                          category: NotificationCategory.appUpdates,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: AppLayout.scaleWidth(context, 40),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF069494),
                size: AppLayout.scaleWidth(context, 20),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }
}
