import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/shimmer_widget.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/tier/tier_requirements.dart';
import 'package:kudipay/presentation/email/change_email_screen.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/notification/notification_preference_screen.dart';
import 'package:kudipay/presentation/tier/upgrade_tier_screen.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';


// ── SVG icon paths ──────────────────────────────────────────────────────────
const _iconPerson = 'assets/icons/person.svg';
const _iconEmail  = 'assets/icons/email.svg';
const _iconPhone  = 'assets/icons/phone.svg';
const _iconBell   = 'assets/icons/bell.svg';
const _iconLock   = 'assets/icons/lock.svg';
const _iconFaceId = 'assets/icons/face_id.svg';

// Extra colour not in AppColors
const _iconTeal  = Color(0xFF339992);
const _headerBg  = Color(0xFFE8F5F3);
const _iconBg    = Color(0xFFF5F5F5);
const _dividerC  = Color(0xFFF0F0F0);
const _arrowC    = Color(0xFFBDBDBD);
const _phoneFg   = Color(0xFF5C5C5C);
const _tierSub   = Color(0xFF777777);

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _faceIdPasscode    = false;
  bool _faceIdTransaction = false;

  @override
  Widget build(BuildContext context) {
    final user           = ref.watch(currentUserProvider);
    final userInfo       = ref.watch(userInfoProvider);
    // SLICE 7 (P0-3): the tier card derives from the server-authoritative
    // GRANTED tier, never the local tierProvider.
    final currentTierObj = _currentTierObject(user);

    final firstName = userInfo?.firstName ??
        user?.name?.split(' ').first ?? 'User';
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
              _buildTierCard(context, currentTierObj, user),
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
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const NotificationPreferenceScreen(),
                )),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              _sectionLabel(context, 'Security'),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              _buildSingleCard(context,
                svgPath: _iconLock,
                title: 'Change Transaction PIN',
                showArrow: true,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              _buildSingleCard(context,
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

              _buildSingleCard(context,
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

  // ── Header card ─────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(BuildContext context, user, String firstName) {
    final photoSize    = AppLayout.scaleWidth(context, 40);
    final photoRadius  = AppLayout.scaleWidth(context, 6);
    // SLICE 7 (P0-3): the header shows the server-authoritative GRANTED tier.
    final tierNumber   = _grantedTierNumber(user);

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
                    // SLICE 6 (MO-6): live KYC status badge — no more
                    // hardcoded "Verified". Derived from the server's typed
                    // KYC state cached on the UserModel.
                    _buildKycBadge(context, user),
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
                    tierNumber > 0 ? 'Tier $tierNumber' : 'UNVERIFIED',
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

  // ── Tier card ────────────────────────────────────────────────────────────────
  Widget _buildTierCard(BuildContext context, currentTierObj, user) {
    final iconBoxSize = AppLayout.scaleWidth(context, 38);
    // SLICE 7 (P0-3): distinguish pending from granted. "pending" only when a
    // tier is being worked toward (pendingTier) but has NOT been granted —
    // pendingTier is never shown as the granted tier, and the granted tier is
    // the server-authoritative user.grantedTier (0 = UNVERIFIED).
    final granted = user.grantedTierOrZero;
    final pending = user.pendingTier != null &&
        user.pendingTier! > granted;
    final tierName = granted >= 1 ? currentTierObj.name : 'UNVERIFIED';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 14),
      ),
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
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.12),
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
                        text: tierName,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (granted >= 1)
                        TextSpan(
                          text: ' (Tier ${currentTierObj.tierNumber})',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 13),
                            fontWeight: FontWeight.w400,
                            color: _tierSub,
                          ),
                        ),
                      if (pending)
                        TextSpan(
                          text: ' — pending',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 3)),
                Text(
                  'Single Transaction Max: ₦${_fmtAmount(currentTierObj.dailySendLimit)}',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey),
                ),
                Text(
                  'Max Balance: ₦${_fmtAmount(currentTierObj.dailyReceiveLimit)}',
                  style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey),
                ),
              ],
            ),
          ),

          // SLICE 8 (MO-8.1): the upgrade entry always points at the SINGLE
          // next tier above the granted tier (no-skip 1 -> 2 -> 3, PRD §2.2.4).
          // UNVERIFIED (0) users have no tier to upgrade — they enter the KYC
          // funnel directly. Mega (3) is the max — the button is hidden.
          if (granted == 0)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const KycFlowManager(),
              )),
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
                'Start KYC',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 10),
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (nextUpgradeTier(granted) != null)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => UpgradeTierScreen(tier: nextUpgradeTier(granted)!),
              )),
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

  // ── Personal info grouped card ────────────────────────────────────────────────
  Widget _buildPersonalInfoCard(BuildContext context, String fullName, user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ChangeEmailScreen()))),
          _divider(context),
          _infoRow(context,
              svgPath: _iconPhone,
              title: _maskPhone(user.phoneNumber),
              subtitle: 'Phone number',
              isLast: true),
          // SLICE 6 (MO-6): masked BVN / NIN from the cached server KYC state.
          _divider(context),
          _infoRow(context,
              svgPath: _iconLock,
              title: _maskedBvn(user),
              subtitle: user.isBvnVerified ? 'BVN verified' : 'BVN not linked',
              isLast: false),
          _divider(context),
          _infoRow(context,
              svgPath: _iconLock,
              title: _maskedNin(user),
              subtitle: user.isNinVerified ? 'NIN verified' : 'NIN not linked',
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

  // ── Single-row card ───────────────────────────────────────────────────────────
  Widget _buildSingleCard(
    BuildContext context, {
    required String svgPath,
    required String title,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
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

  // ── Switch card ───────────────────────────────────────────────────────────────
  Widget _buildSwitchCard(
    BuildContext context, {
    required String svgPath,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
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
              activeColor: AppColors.primaryTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout card ───────────────────────────────────────────────────────────────
  Widget _buildLogoutCard(BuildContext context) {
    final iconBoxSize = AppLayout.scaleWidth(context, 36);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16)),
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
                    color: _iconTeal,
                    size: AppLayout.scaleWidth(context, 18)),
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

  // ── Shared helpers ────────────────────────────────────────────────────────────

  // SLICE 7 (P0-3): the server-authoritative GRANTED tier number, or 0 when no
  // tier has been granted (UNVERIFIED). Pending/selected/local-provider tiers
  // are routing intent and are never displayed as the granted tier.
  int _grantedTierNumber(user) {
    final granted = user?.grantedTier as int?;
    if (granted != null && granted >= 1 && granted <= 3) return granted;
    return 0;
  }

  // SLICE 7 (P0-3): the tier card object derives from the granted tier, never
  // the local tierProvider. UNVERIFIED falls back to the entry-tier object but
  // is labelled UNVERIFIED (see _buildTierCard) — no fabricated grant.
  UpgradeTier _currentTierObject(user) {
    final granted = user?.grantedTierOrZero ?? 0;
    switch (granted) {
      case 3:
        return UpgradeTier.megaTier();
      case 2:
        return UpgradeTier.proTier();
      default:
        return UpgradeTier.basicTier();
    }
  }

  // SLICE 6 (MO-6): live KYC status badge derived from server typed state.
  Widget _buildKycBadge(BuildContext context, user) {
    final (label, color) = _kycStatusBadge(user);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 8),
        vertical: AppLayout.scaleHeight(context, 4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.kycStatus == KycStatus.verified
                ? Icons.check_circle_outline
                : user.kycStatus == KycStatus.rejected
                    ? Icons.error_outline
                    : Icons.hourglass_top_outlined,
            size: AppLayout.scaleWidth(context, 13),
            color: color,
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 3)),
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 11),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _kycStatusBadge(user) {
    // Address verification pending is the PRD's interim Mega state.
    if (user.addressStatus == AddressVerificationStatus.pendingAgentVisit) {
      return ('Address verification in progress', const Color(0xFFF57C00));
    }
    switch (user.kycStatus) {
      case KycStatus.verified:
        return ('Verified', AppColors.primaryTeal);
      case KycStatus.manualReview:
        return ('Under review', const Color(0xFFF57C00));
      case KycStatus.rejected:
        return ('Verification failed', const Color(0xFFD32F2F));
      case KycStatus.expired:
        return ('Verification expired', const Color(0xFFF57C00));
      case KycStatus.pending:
      case KycStatus.inProgress:
      case KycStatus.notStarted:
        return ('KYC in progress', const Color(0xFFF57C00));
    }
    // Defensive fallback (user is dynamically typed here; switch is exhaustive
    // for KycStatus but the analyzer can't prove it for a dynamic receiver).
    return ('KYC in progress', const Color(0xFFF57C00));
  }

  Widget _svgIcon(BuildContext context, String path) {
    final boxSize  = AppLayout.scaleWidth(context, 36);
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
      padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16)),
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

  String _maskedBvn(user) {
    final bvn = user.bvn as String?;
    if (bvn == null || bvn.isEmpty) return 'Not linked';
    return _maskDigits(bvn);
  }

  String _maskedNin(user) {
    final nin = user.nin as String?;
    if (nin == null || nin.isEmpty) return 'Not linked';
    return _maskDigits(nin);
  }

  String _maskDigits(String value) {
    if (value.length <= 4) return '****';
    return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
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
            borderRadius: BorderRadius.circular(
                AppLayout.scaleWidth(context, 16))),
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppLayout.scaleWidth(context, 8)),
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

// ── File-level helper ─────────────────────────────────────────────────────────
String _formatAmount(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}