// lib/main.dart
// FIXED:
//   - availableCamerasProvider has a safe [] fallback (no more bare UnimplementedError)
//   - AppLayout.lockPortrait() called before runApp so landscape devices
//     are forced to portrait at launch
//   - ConnectivityService initialised before runApp as before
//   - home: replaced with onGenerateRoute + initialRoute so all navigation
//     goes through AppRouter (single source of truth).
//   - ConnectivityBanner lifted into MaterialApp.builder so it wraps every
//     route, not just the splash screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/routes/app_route.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:camera/camera.dart';

// FIXED: provides an empty-list default so watching the provider before
// main() finishes never throws UnimplementedError.
final availableCamerasProvider =
    Provider<List<CameraDescription>>((ref) => const []);

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KudiKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PolySans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF069494),
        ),
      ),
      // CHANGED: replaced home: with onGenerateRoute + initialRoute so all
      // navigation flows through AppRouter — the single source of truth.
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.splash,
      // CHANGED: ConnectivityBanner moved into builder so it wraps every
      // route in the app, not just the splash screen.
      builder: (context, child) => ConnectivityBanner(child: child!),
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