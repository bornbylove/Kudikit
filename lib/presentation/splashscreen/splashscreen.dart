import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/formatting/widget/page_transition.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/onboarding/onboarding_screen.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/auth/session_lock_provider.dart';
import 'package:kudipay/provider/onboarding/onboarding_provider.dart';


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
      // SLICE 6: always route through KycFlowManager — it is tier-aware and
      // routes completed users to the main shell (BottomNavBar → Home) while
      // funnelling Pro/Mega users who have not finished ID/address, and it
      // surfaces async states (review/pending agent visit/rejected) instead of
      // assuming top-level VERIFIED == KYC complete (which is false for
      // Pro/Mega, whose top-level status flips to VERIFIED after just BVN/NIN).
      destination = const KycFlowManager();

      // PRD §2.1.5.3: "Biometric prompt appears if previously enrolled" is a
      // returning-user login behavior — a cold start with a cached session
      // must be gated (biometric or passcode fallback), not silently
      // resumed. arm() then lockNow() puts the app straight into the locked
      // phase so _SessionLockOverlay (main.dart) shows AppLockScreen over
      // whatever `destination` renders on its first frame; the cached token
      // itself is untouched either way.
      final lockNotifier = ref.read(sessionLockProvider.notifier);
      await lockNotifier.arm();
      if (!mounted) return;
      lockNotifier.lockNow();
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