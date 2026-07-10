import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/agent/become_agent_screen.dart';
import 'package:kudipay/presentation/cashout/cashout_map_screen.dart';

class CashoutMenuScreen extends StatelessWidget {
  const CashoutMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cashout Menu',
          style: TextStyle(
            fontFamily: 'PolySans',
            color: AppColors.textDark,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Column(
          children: [
            _MenuCard(
              svgAsset: 'assets/icons/hand.svg',
              title: 'Request Money from Agent',
              subtitle: 'Get cash from a nearby agent.',
              iconBackgroundColor: const Color(0xFFDCEFF9),
              iconColor: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CashOutMapScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _MenuCard(
              svgAsset: 'assets/icons/receipt.svg',
              title: 'Become a Kudikit Agent',
              subtitle: 'Earn by serving as an agent.',
              iconBackgroundColor: const Color(0xFFDCF0E5),
              iconColor: AppColors.primaryTeal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BecomeAgentLandingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String subtitle;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 18),
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: AppLayout.scaleWidth(context, 12),
                offset: Offset(0, AppLayout.scaleHeight(context, 4)),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: AppLayout.scaleWidth(context, 30),
                height: AppLayout.scaleWidth(context, 30),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    svgAsset,
                    width: AppLayout.scaleWidth(context, 17),
                    height: AppLayout.scaleWidth(context, 17),
                    colorFilter: ColorFilter.mode(
                      iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 14)),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 3)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'PolySans',
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppLayout.scaleWidth(context, 14),
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
