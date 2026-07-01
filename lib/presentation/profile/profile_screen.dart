import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/presentation/email/change_email_screen.dart';

import 'package:kudipay/presentation/notification/notification_preference_screen.dart';

import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';

// -- SVG icon paths ----------------------------------------------------------
const _iconPerson = 'assets/icons/person.svg';
const _iconEmail = 'assets/icons/email.svg';
const _iconPhone = 'assets/icons/phone.svg';
const _iconBell = 'assets/icons/bell.svg';
const _iconLock = 'assets/icons/lock.svg';
const _iconFaceId = 'assets/icons/face_id.svg';

// Extra colour not in AppColors
const _iconTeal = Color(0xFF339992);
const _headerBg = Color(0xFFE8F5F3);
const _iconBg = Color(0xFFF5F5F5);
const _dividerC = Color(0xFFF0F0F0);
const _arrowC = Color(0xFFBDBDBD);
const _phoneFg = Color(0xFF5C5C5C);
const _tierSub = Color(0xFF777777);

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _faceIdPasscode = false;
  bool _faceIdTransaction = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userInfo = ref.watch(userInfoProvider);
    final tierState = ref.watch(tierProvider);
    final currentTierObj = tierState.getTierObject();

    final firstName =
        userInfo?.firstName ?? user?.name?.split(' ').first ?? 'User';
    final fullName = userInfo != null
        ? '${userInfo.firstName} ${userInfo.lastName ?? ''}'.trim()
        : user?.name ?? 'Full name not set';

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundScreen,
        body: SafeArea(child: ProfileShimmer()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textDark,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'PolySans',
            color: AppColors.textDark,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
        color: AppColors.primaryTeal,
        backgroundColor: AppColors.backgroundScreen,
        strokeWidth: 1.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, user, firstName),
              SizedBox(height: AppLayout.scaleHeight(context, 20)),
              _sectionLabel(context, 'Current tier'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildTierCard(context, currentTierObj),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              _sectionLabel(context, 'Personal Information'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildPersonalInfoCard(context, fullName, user),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSingleCard(
                context,
                svgPath: _iconBell,
                title: 'Notification Preference',
                showArrow: true,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationPreferenceScreen(),
                    )),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              _sectionLabel(context, 'Security'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSingleCard(
                context,
                svgPath: _iconLock,
                title: 'Change Transaction PIN',
                showArrow: true,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSingleCard(
                context,
                svgPath: _iconLock,
                title: 'Change Passcode',
                showArrow: true,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSwitchCard(
                context,
                svgPath: _iconFaceId,
                title: 'Use Face ID',
                subtitle: 'For passcode',
                value: _faceIdPasscode,
                onChanged: (v) => setState(() => _faceIdPasscode = v),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSwitchCard(
                context,
                svgPath: _iconFaceId,
                title: 'Use Face ID',
                subtitle: 'For transaction PIN',
                value: _faceIdTransaction,
                onChanged: (v) => setState(() => _faceIdTransaction = v),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              _buildSingleCard(
                context,
                svgPath: _iconPhone,
                title: 'App management',
                showArrow: true,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildLogoutCard(context),
              SizedBox(height: AppLayout.scaleHeight(context, 100)),
            ],
          ),
        ),
      ),
    );
  }

  // -- Header card -------------------------------------------------------------
  Widget _buildHeaderCard(BuildContext context, user, String firstName) {
    final photoSize = AppLayout.scaleWidth(context, 40);
    final photoRadius = AppLayout.scaleWidth(context, 6);
    final tierNumber = ref.watch(tierProvider).getTierObject().tierNumber;

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 16),
        AppLayout.scaleWidth(context, 16),
        0,
      ),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          ClipRRect(
            borderRadius: BorderRadius.circular(photoRadius),
            child: Image.asset(
              'assets/images/img_placeholder.png',
              width: photoSize,
              height: photoSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: photoSize,
                height: photoSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(photoRadius),
                ),
                child: Icon(Icons.person,
                    color: AppColors.white,
                    size: AppLayout.scaleWidth(context, 32)),
              ),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),

          // Name / phone / tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, $firstName',
                        style: TextStyle(
                          fontFamily: 'PolySans',
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 5)),
                    // Verified badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 8),
                        vertical: AppLayout.scaleHeight(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 20)),
                        border: Border.all(
                            color:
                                AppColors.primaryTeal.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: AppLayout.scaleWidth(context, 13),
                              color: AppColors.primaryTeal),
                          SizedBox(width: AppLayout.scaleWidth(context, 3)),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 11),
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),

                Text(
                  user.phoneNumber,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: _phoneFg,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 10)),

                // Tier pill
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 12),
                    vertical: AppLayout.scaleHeight(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 20)),
                  ),
                  child: Text(
                    'Tier $tierNumber',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 10),
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Tier card ----------------------------------------------------------------
  Widget _buildTierCard(BuildContext context, currentTierObj) {
    final iconBoxSize = AppLayout.scaleWidth(context, 38);

    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            ),
            child: Icon(currentTierObj.icon,
                color: AppColors.primaryTeal,
                size: AppLayout.scaleWidth(context, 20)),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: currentTierObj.name,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextSpan(
                        text: ' (Tier ${currentTierObj.tierNumber})',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          fontWeight: FontWeight.w400,
                          color: _tierSub,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 3)),
                Text(
                  'Single Transaction Max: ?${_fmtAmount(currentTierObj.dailySendLimit)}',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey),
                ),
                Text(
                  'Max Balance: ?${_fmtAmount(currentTierObj.dailyReceiveLimit)}',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.upgradeTier,
                arguments: UpgradeTierArgs(tier: currentTierObj)),
            style: TextButton.styleFrom(
              backgroundColor: _headerBg,
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 14),
                vertical: AppLayout.scaleHeight(context, 7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Upgrade Tier',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 10),
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Personal info grouped card ------------------------------------------------
  Widget _buildPersonalInfoCard(BuildContext context, String fullName, user) {
    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(context,
              svgPath: _iconPerson,
              title: fullName,
              subtitle: 'Full name',
              isFirst: true),
          _divider(context),
          _infoRow(context,
              svgPath: _iconEmail,
              title: _maskEmail(user.email),
              subtitle: 'Email address',
              showArrow: true,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangeEmailScreen()))),
          _divider(context),
          _infoRow(context,
              svgPath: _iconPhone,
              title: _maskPhone(user.phoneNumber),
              subtitle: 'Phone number',
              isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String svgPath,
    required String title,
    required String subtitle,
    bool showArrow = false,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst
            ? Radius.circular(AppLayout.scaleWidth(context, 12))
            : Radius.zero,
        bottom: isLast
            ? Radius.circular(AppLayout.scaleWidth(context, 12))
            : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 14),
        ),
        child: Row(
          children: [
            _svgIcon(context, svgPath),
            SizedBox(width: AppLayout.scaleWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(Icons.arrow_forward_ios,
                  size: AppLayout.scaleWidth(context, 14), color: _arrowC),
          ],
        ),
      ),
    );
  }

  // -- Single-row card -----------------------------------------------------------
  Widget _buildSingleCard(
    BuildContext context, {
    required String svgPath,
    required String title,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 14),
          ),
          child: Row(
            children: [
              _svgIcon(context, svgPath),
              SizedBox(width: AppLayout.scaleWidth(context, 14)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (showArrow)
                Icon(Icons.arrow_forward_ios,
                    size: AppLayout.scaleWidth(context, 14), color: _arrowC),
            ],
          ),
        ),
      ),
    );
  }

  // -- Switch card ---------------------------------------------------------------
  Widget _buildSwitchCard(
    BuildContext context, {
    required String svgPath,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 12),
        ),
        child: Row(
          children: [
            _svgIcon(context, svgPath),
            SizedBox(width: AppLayout.scaleWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primaryTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // -- Logout card ---------------------------------------------------------------
  Widget _buildLogoutCard(BuildContext context) {
    final iconBoxSize = AppLayout.scaleWidth(context, 36);

    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 14),
          ),
          child: Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
                ),
                child: Icon(Icons.logout,
                    color: _iconTeal, size: AppLayout.scaleWidth(context, 18)),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 14)),
              Expanded(
                child: Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: AppLayout.scaleWidth(context, 14), color: _arrowC),
            ],
          ),
        ),
      ),
    );
  }

  // -- Shared helpers ------------------------------------------------------------

  Widget _svgIcon(BuildContext context, String path) {
    final boxSize = AppLayout.scaleWidth(context, 36);
    final iconSize = AppLayout.scaleWidth(context, 16);
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: _iconBg,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
      ),
      child: Center(
        child: SvgPicture.asset(
          path,
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(_iconTeal, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      child: Text(
        text,
        style: AppTextStyles.responsiveLabel(context).copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppLayout.scaleWidth(context, 66),
      endIndent: 0,
      color: _dividerC,
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    if (username.length <= 1) return email;
    return '${username[0]}${'*' * 7}@${parts[1]}';
  }

  String _maskPhone(String phone) {
    if (phone.length < 8) return phone;
    return '+234******${phone.substring(phone.length - 4)}';
  }

  String _fmtAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 16))),
        title: Text(
          'Log out',
          style: TextStyle(fontSize: AppLayout.fontSize(context, 16)),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: AppLayout.fontSize(context, 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: AppLayout.fontSize(context, 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
              ),
            ),
            child: Text(
              'Log out',
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppLayout.fontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- File-level helper ---------------------------------------------------------
String _formatAmount(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}
