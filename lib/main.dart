// lib/main.dart
// FIXED:
//   - availableCamerasProvider has a safe [] fallback (no more bare UnimplementedError)
//   - AppLayout.lockPortrait() called before runApp so landscape devices
//     are forced to portrait at launch
//   - ConnectivityService initialised before runApp as before

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
// import 'package:kudipay/provider/connectivity_provider.dart';
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
      home: const ConnectivityBanner(
        child: SplashScreen(),
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