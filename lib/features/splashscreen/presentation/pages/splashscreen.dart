import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'package:kudipay/features/auth/presentation/pages/login_page.dart';
import 'package:kudipay/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:kudipay/features/homescreen/presentation/pages/home_screen.dart';
import 'package:kudipay/features/kyc/presentation/pages/kyc_flow_manager.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/onboarding/presentation/controllers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });

    Timer(const Duration(seconds: 3), _navigateToNextScreen);
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // Wait for auth state to be checked
    final authState = ref.read(authProvider);

    // Check onboarding status
    final hasSeenOnboarding = await ref.read(hasSeenOnboardingProvider.future);

    if (!mounted) return;

    Widget destination;

    // Navigation logic:
    // 1. If authenticated → Home (if KYC complete) or KYC flow
    // 2. If not authenticated but seen onboarding → Login
    // 3. If not seen onboarding → Onboarding

    if (authState.status == AuthStatus.authenticated) {
      if (authState.user!.isKycComplete) {
        destination = const HomeScreen();
      } else {
        destination = const KycFlowManager();
      }
    } else if (hasSeenOnboarding) {
      destination = const LoginPage();
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageTransition(destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: logoSize,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SvgPicture.asset(
                  'assets/icons/Kudikit Iconmark teal.svg',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
