// lib/main.dart
// FIXED:
//   - availableCamerasProvider has a safe [] fallback (no more bare UnimplementedError)
//   - AppLayout.lockPortrait() called before runApp so landscape devices
//     are forced to portrait at launch
//   - ConnectivityService initialised before runApp as before

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/root_navigator.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/presentation/lock/app_lock_screen.dart';
import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
// import 'package:kudipay/provider/connectivity_provider.dart';
import 'package:kudipay/provider/auth/session_lock_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:camera/camera.dart';


final availableCamerasProvider = Provider<List<CameraDescription>>((ref) => const []);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIXED: Lock to portrait before runApp so no landscape flash on first frame.
  await AppLayout.lockPortrait();

  // Initialise cameras — override the provider with real cameras.
  final cameras = await availableCameras();

  // Initialise connectivity service.
  await ConnectivityService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        availableCamerasProvider.overrideWithValue(cameras),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // SLICE 6 (MO-4): app-resume reconciliation. The auth-service can change KYC
  // state asynchronously (address poller PENDING_AGENT_VISIT -> VERIFIED,
  // MANUAL_REVIEW -> VERIFIED/REJECTED). A resumed app must discover that
  // without a logout/login — best-effort and non-blocking.
  //
  // Also drives PRD §2.1.5.4 auto-logout: backgrounding doesn't pause the
  // wall clock, so a long background stint must lock immediately on resume
  // rather than wait for the in-foreground idle ticker to catch up.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).refreshKycStatus();
      ref.read(sessionLockProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-logout (session_lock_provider.dart) only re-locks the UI — it
    // never touches tokens. A real session end (explicit logout, or the
    // refresh-token failing) must stop the idle timer too, or a freshly
    // shown LoginPage would immediately get shadowed by AppLockScreen.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status != AuthStatus.authenticated) {
        ref.read(sessionLockProvider.notifier).disarm();
      }
    });

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'KudiKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PolySans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF069494),
        ),
      ),
      builder: (context, child) => _SessionLockOverlay(child: child),
      home: const ConnectivityBanner(
        child: SplashScreen(),
      ),
    );
  }
}

// =============================================================================
// _SessionLockOverlay
// -----------------------------------------------------------------------------
// Sits above every route via MaterialApp.builder so it doesn't matter which
// screen is on top when the idle timer fires. Two responsibilities:
//   1. Feed every tap/scroll back into SessionLockNotifier.recordActivity()
//      (SessionLockNotifier itself no-ops until arm() has been called from
//      BottomNavBar, so this is harmless before login/KYC completion).
//   2. Show the 60-second warning, then AppLockScreen, when the timer fires.
// =============================================================================
class _SessionLockOverlay extends ConsumerWidget {
  final Widget? child;
  const _SessionLockOverlay({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(sessionLockProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(sessionLockProvider.notifier).recordActivity(),
      child: Stack(
        children: [
          if (child != null) child!,
          if (lockState.phase == SessionLockPhase.warning)
            _InactivityWarningBanner(
              onStayLoggedIn: () =>
                  ref.read(sessionLockProvider.notifier).recordActivity(),
            ),
          if (lockState.phase == SessionLockPhase.locked) const AppLockScreen(),
        ],
      ),
    );
  }
}

class _InactivityWarningBanner extends StatelessWidget {
  final VoidCallback onStayLoggedIn;
  const _InactivityWarningBanner({required this.onStayLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24 + MediaQuery.of(context).padding.bottom,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You\'ll be logged out soon due to inactivity',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: onStayLoggedIn,
                  child: const Text(
                    'Stay logged in',
                    style: TextStyle(
                      color: Color(0xFF4DD0C4),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppWithConnectivity extends ConsumerWidget {
  final Widget child;
  const AppWithConnectivity({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null && !previous!.value! && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
    return child;
  }
}