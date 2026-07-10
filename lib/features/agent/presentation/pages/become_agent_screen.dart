import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'tier_check_screen.dart';

class BecomeAgentLandingScreen extends StatelessWidget {
  const BecomeAgentLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 20),
          vertical: AppLayout.scaleHeight(context, 8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Hero icon
            Container(
              width: AppLayout.scaleWidth(context, 72),
              height: AppLayout.scaleWidth(context, 72),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white,
                size: AppLayout.scaleWidth(context, 36),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Title
            Text(
              'Become a KudiKit Agent',
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 22),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            Text(
              'Turn your business into a cash withdrawal point and earn daily',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: AppColors.textGrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Why become an agent card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Become an Agent?',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  const _BenefitRow(
                    icon: Icons.trending_up_rounded,
                    title: 'Earn Commission',
                    subtitle:
                        'Get paid ?50–?200 for every withdrawal you process',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 14)),
                  const _BenefitRow(
                    icon: Icons.people_outline_rounded,
                    title: 'Serve Your Community',
                    subtitle: 'Help neighbors access cash conveniently',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 14)),
                  const _BenefitRow(
                    icon: Icons.access_time_rounded,
                    title: 'Flexible Hours',
                    subtitle: 'Set your own schedule and availability',
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Requirements card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 14)),
                  const _RequirementRow('Tier 2 KYC verification completed'),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  const _RequirementRow('Minimum ?50,000 cash float'),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  const _RequirementRow('Valid business location'),
                  SizedBox(height: AppLayout.scaleHeight(context, 10)),
                  const _RequirementRow('Active bank account'),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 100)),
          ],
        ),
      ),
      bottomNavigationBar: _PrimaryButton(
        label: 'Start Verification',
        onPressed: () => Navigator.push(
          context,
          PageTransition(const TierCheckScreen()),
        ),
      ),
    );
  }
}

// -- Sub-widgets ---------------------------------------------------------------

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppLayout.scaleWidth(context, 38),
          height: AppLayout.scaleWidth(context, 38),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          ),
          child: Icon(icon,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 20)),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'PolySans',
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
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String text;
  const _RequirementRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline,
            color: AppColors.primaryTeal,
            size: AppLayout.scaleWidth(context, 18)),
        SizedBox(width: AppLayout.scaleWidth(context, 10)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// -- Shared local widgets ------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 12),
            offset: Offset(0, AppLayout.scaleHeight(context, 4)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading = false;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 28),
      ),
      color: AppColors.backgroundScreen,
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null
                ? AppColors.primaryTeal
                : AppColors.primaryTeal.withValues(alpha: 0.4),
            disabledBackgroundColor:
                AppColors.primaryTeal.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: AppLayout.scaleWidth(context, 22),
                  height: AppLayout.scaleWidth(context, 22),
                  child: const CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 1,
                    strokeCap: StrokeCap.round,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.responsiveButtonText(context),
                ),
        ),
      ),
    );
  }
}
