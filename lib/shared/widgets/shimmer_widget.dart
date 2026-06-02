import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kudipay/core/utils/responsive.dart';

// ---------------------------------------------------------------------------
// Base helper — a single shimmer block (rounded rectangle)
// ---------------------------------------------------------------------------
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer wrapper — applies the animated gradient to any child skeleton
// ---------------------------------------------------------------------------
class KudiShimmer extends StatelessWidget {
  final Widget child;

  const KudiShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

// ===========================================================================
// 1. TRANSACTION LIST SHIMMER
// Replaces: CircularProgressIndicator in TransactionsScreen when
//           state.isLoading && state.transactions.isEmpty
//
// File: lib/presentation/transaction/transaction_screen.dart
// ===========================================================================
class TransactionListShimmer extends StatelessWidget {
  final int itemCount;
  const TransactionListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 12),
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
        itemBuilder: (_, __) => _TransactionItemSkeleton(),
      ),
    );
  }
}

class _TransactionItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: AppLayout.scaleWidth(context, 44),
            height: AppLayout.scaleWidth(context, 44),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 140), height: 14),
                SizedBox(height: AppLayout.scaleHeight(context, 6)),
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 90), height: 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ShimmerBox(
                  width: AppLayout.scaleWidth(context, 70), height: 14),
              SizedBox(height: AppLayout.scaleHeight(context, 6)),
              _ShimmerBox(
                  width: AppLayout.scaleWidth(context, 50), height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 2. BANK LIST SHIMMER
// Replaces: CircularProgressIndicator in SelectBankScreen when
//           banksState.isLoading && banksState.banks.isEmpty
//
// File: lib/presentation/bankdeposit/select_bank.dart
// ===========================================================================
class BankListShimmer extends StatelessWidget {
  final int itemCount;
  const BankListShimmer({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 8),
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: const Color(0xFFEEEEEE),
          indent: AppLayout.scaleWidth(context, 64),
        ),
        itemBuilder: (_, __) => _BankItemSkeleton(),
      ),
    );
  }
}

class _BankItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: AppLayout.scaleHeight(context, 14)),
      child: Row(
        children: [
          // Bank logo circle
          Container(
            width: AppLayout.scaleWidth(context, 40),
            height: AppLayout.scaleWidth(context, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 14)),
          _ShimmerBox(
              width: AppLayout.scaleWidth(context, 180), height: 14),
        ],
      ),
    );
  }
}

// ===========================================================================
// 3. NOTIFICATION PREFERENCES SHIMMER
// Replaces: CircularProgressIndicator in NotificationPreferenceScreen
//           (preferencesState.when loading:)
//
// File: lib/presentation/notification/notification_preference_screen.dart
// File: lib/presentation/notification/notification_category_screen.dart
// ===========================================================================
class NotificationPrefsShimmer extends StatelessWidget {
  const NotificationPrefsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: EdgeInsets.only(
                  bottom: AppLayout.scaleHeight(context, 12)),
              child: _NotifPrefRowSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifPrefRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 160), height: 14),
                SizedBox(height: AppLayout.scaleHeight(context, 6)),
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 220), height: 11),
              ],
            ),
          ),
          // Toggle skeleton
          Container(
            width: AppLayout.scaleWidth(context, 44),
            height: AppLayout.scaleHeight(context, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 4. DATA PLANS SHIMMER
// Replaces: CircularProgressIndicator in DataPlanScreen when
//           state.isLoadingPlans
//
// File: lib/presentation/bill/data/data_plan_screen.dart
// ===========================================================================
class DataPlanShimmer extends StatelessWidget {
  const DataPlanShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppLayout.scaleWidth(context, 12),
          mainAxisSpacing: AppLayout.scaleHeight(context, 12),
          childAspectRatio: 1.6,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _DataPlanCardSkeleton(),
      ),
    );
  }
}

class _DataPlanCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ShimmerBox(
              width: AppLayout.scaleWidth(context, 80), height: 16),
          _ShimmerBox(
              width: AppLayout.scaleWidth(context, 60), height: 12),
          _ShimmerBox(
              width: double.infinity, height: 11),
        ],
      ),
    );
  }
}

// ===========================================================================
// 5. HOME SCREEN BALANCE CARD SHIMMER
// Used in HomeScreen while userInfo / tier data is loading (null state)
//
// File: lib/presentation/homescreen/home_screen.dart
// ===========================================================================
class HomeBalanceCardShimmer extends StatelessWidget {
  const HomeBalanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 12),
        ),
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 100), height: 13),
                Container(
                  width: AppLayout.scaleWidth(context, 28),
                  height: AppLayout.scaleWidth(context, 28),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            _ShimmerBox(
                width: AppLayout.scaleWidth(context, 180), height: 32),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Row(
              children: [
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 120), height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 6. HOME SCREEN RECENT TRANSACTIONS SHIMMER
// Shown in the "Recent Transactions" section of HomeScreen while loading
//
// File: lib/presentation/homescreen/home_screen.dart
// ===========================================================================
class HomeRecentTransactionsShimmer extends StatelessWidget {
  final int itemCount;
  const HomeRecentTransactionsShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: Column(
        children: List.generate(
          itemCount,
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: AppLayout.scaleHeight(context, 10),
              left: AppLayout.scaleWidth(context, 16),
              right: AppLayout.scaleWidth(context, 16),
            ),
            child: _TransactionItemSkeleton(),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 7. CONTACT / RECIPIENT LIST SHIMMER
// Replaces: CircularProgressIndicator while contacts are loading
//
// File: lib/formatting/widget/contact_picker_buttom_sheet.dart
// ===========================================================================
class ContactListShimmer extends StatelessWidget {
  final int itemCount;
  const ContactListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16)),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(
              vertical: AppLayout.scaleHeight(context, 10)),
          child: Row(
            children: [
              Container(
                width: AppLayout.scaleWidth(context, 44),
                height: AppLayout.scaleWidth(context, 44),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                        width: AppLayout.scaleWidth(context, 130), height: 14),
                    SizedBox(height: AppLayout.scaleHeight(context, 5)),
                    _ShimmerBox(
                        width: AppLayout.scaleWidth(context, 90), height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 8. MY REQUESTS LIST SHIMMER
// Replaces: CircularProgressIndicator in MyRequestsScreen while loading
//
// File: lib/presentation/request/my_request_screen.dart
// ===========================================================================
class RequestListShimmer extends StatelessWidget {
  final int itemCount;
  const RequestListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: ListView.separated(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
        itemBuilder: (_, __) => _RequestItemSkeleton(),
      ),
    );
  }
}

class _RequestItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Row(
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 42),
            height: AppLayout.scaleWidth(context, 42),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 120), height: 13),
                SizedBox(height: AppLayout.scaleHeight(context, 5)),
                _ShimmerBox(
                    width: AppLayout.scaleWidth(context, 80), height: 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ShimmerBox(
                  width: AppLayout.scaleWidth(context, 70), height: 13),
              SizedBox(height: AppLayout.scaleHeight(context, 5)),
              Container(
                width: AppLayout.scaleWidth(context, 55),
                height: AppLayout.scaleHeight(context, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 9. PROFILE SCREEN SHIMMER
// Used while user data loads in UserProfileScreen
//
// File: lib/presentation/profile/profile_screen.dart
// ===========================================================================
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return KudiShimmer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Container(
              margin: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 60),
                    height: AppLayout.scaleWidth(context, 60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 16)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                          width: AppLayout.scaleWidth(context, 130), height: 16),
                      SizedBox(height: AppLayout.scaleHeight(context, 6)),
                      _ShimmerBox(
                          width: AppLayout.scaleWidth(context, 90), height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // Menu rows
            ...List.generate(
              6,
              (_) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 6),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppLayout.scaleWidth(context, 36),
                        height: AppLayout.scaleWidth(context, 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppLayout.scaleWidth(context, 8)),
                        ),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 14)),
                      _ShimmerBox(
                          width: AppLayout.scaleWidth(context, 160), height: 14),
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
}