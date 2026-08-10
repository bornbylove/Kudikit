import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/features/notification/presentation/pages/notification_preferences.dart';
import 'package:kudipay/features/notification/presentation/controllers/notification_provider.dart';

class NotificationCategoryScreen extends ConsumerWidget {
  final NotificationCategory category;

  const NotificationCategoryScreen({
    super.key,
    required this.category,
  });

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
          data: (preferences) => _buildContent(context, ref, preferences),
          // Fix 1: shimmer instead of spinner
          loading: () => const NotificationPrefsShimmer(),
          // Fix 3: proper error state with retry � previously a dead-end Text widget
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
                      backgroundColor: AppColors.primaryTeal,
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
  Widget _buildContent(BuildContext context, WidgetRef ref,
      NotificationPreferences preferences) {
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
              children: _buildCategoryItems(context, ref, preferences),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryItems(BuildContext context, WidgetRef ref,
      NotificationPreferences preferences) {
    List<Widget> items = [];
    List<Map<String, dynamic>> categoryData = _getCategoryData(preferences);

    for (int i = 0; i < categoryData.length; i++) {
      final item = categoryData[i];
      items.add(
        _buildToggleTile(
          context,
          ref,
          title: item['title'],
          value: item['value'],
          key: item['key'],
        ),
      );

      if (i < categoryData.length - 1) {
        items.add(_buildDivider());
      }
    }

    return items;
  }

  // Fix 2: explicit NotificationPreferences type instead of dynamic
  List<Map<String, dynamic>> _getCategoryData(
      NotificationPreferences preferences) {
    switch (category) {
      case NotificationCategory.transaction:
        return [
          {
            'title': 'Transaction success / failure',
            'value': preferences.transactionSuccess,
            'key': 'transactionSuccess',
          },
          {
            'title': 'Deposit notification',
            'value': preferences.depositNotification,
            'key': 'depositNotification',
          },
          {
            'title': 'Withdrawal notification',
            'value': preferences.withdrawalNotification,
            'key': 'withdrawalNotification',
          },
          {
            'title': 'Large transaction alert',
            'value': preferences.largeTransactionAlert,
            'key': 'largeTransactionAlert',
          },
        ];

      case NotificationCategory.bills:
        return [
          {
            'title': 'Bill payment reminder',
            'value': preferences.billPaymentReminder,
            'key': 'billPaymentReminder',
          },
          {
            'title': 'Failed bill payment alert',
            'value': preferences.failedBillPaymentAlert,
            'key': 'failedBillPaymentAlert',
          },
          {
            'title': 'Large transaction alert',
            'value': preferences.largeTransactionAlert,
            'key': 'largeTransactionAlert',
          },
        ];

      case NotificationCategory.rewards:
        return [
          {
            'title': 'Reward earned alert',
            'value': preferences.rewardEarnedAlert,
            'key': 'rewardEarnedAlert',
          },
          {
            'title': 'Reward expiry alert',
            'value': preferences.rewardExpiryAlert,
            'key': 'rewardExpiryAlert',
          },
          {
            'title': 'Promotional offers',
            'value': preferences.promotionalOffers,
            'key': 'promotionalOffers',
          },
          {
            'title': 'Partner offers',
            'value': preferences.partnerOffers,
            'key': 'partnerOffers',
          },
        ];

      case NotificationCategory.appUpdates:
        return [
          {
            'title': 'New feature announcements',
            'value': preferences.newFeatureAnnouncements,
            'key': 'newFeatureAnnouncements',
          },
          {
            'title': 'Tutorial prompt',
            'value': preferences.tutorialPrompt,
            'key': 'tutorialPrompt',
          },
          {
            'title': 'Feedback request',
            'value': preferences.feedbackRequest,
            'key': 'feedbackRequest',
          },
          {
            'title': 'Announcement banners',
            'value': preferences.announcementBanners,
            'key': 'announcementBanners',
          },
        ];
    }
  }

  Widget _buildToggleTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool value,
    required String key,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: (newValue) async {
                // Fix 5: surface toggle revert failure as a SnackBar so the
                // user knows the change didn't save, instead of silently reverting
                await ref
                    .read(notificationPreferencesProvider.notifier)
                    .togglePreference(key, newValue);

                // Check if the value reverted (toggle failed)
                final currentState =
                    ref.read(notificationPreferencesProvider).value;
                if (currentState != null) {
                  final currentValue = _getValueForKey(currentState, key);
                  if (currentValue != newValue) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.sync_problem,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                      'Could not save change. Please try again.')),
                            ],
                          ),
                          backgroundColor: const Color(0xFFB00020),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                  }
                }
              },
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primaryTeal,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  // Fix 5: helper to read back the saved value after a toggle attempt
  bool _getValueForKey(NotificationPreferences prefs, String key) {
    switch (key) {
      case 'transactionSuccess':
        return prefs.transactionSuccess;
      case 'depositNotification':
        return prefs.depositNotification;
      case 'withdrawalNotification':
        return prefs.withdrawalNotification;
      case 'largeTransactionAlert':
        return prefs.largeTransactionAlert;
      case 'billPaymentReminder':
        return prefs.billPaymentReminder;
      case 'failedBillPaymentAlert':
        return prefs.failedBillPaymentAlert;
      case 'rewardEarnedAlert':
        return prefs.rewardEarnedAlert;
      case 'rewardExpiryAlert':
        return prefs.rewardExpiryAlert;
      case 'promotionalOffers':
        return prefs.promotionalOffers;
      case 'partnerOffers':
        return prefs.partnerOffers;
      case 'newFeatureAnnouncements':
        return prefs.newFeatureAnnouncements;
      case 'tutorialPrompt':
        return prefs.tutorialPrompt;
      case 'feedbackRequest':
        return prefs.feedbackRequest;
      case 'announcementBanners':
        return prefs.announcementBanners;
      default:
        return false;
    }
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
