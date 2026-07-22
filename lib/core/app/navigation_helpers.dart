import 'package:flutter/material.dart';
import 'package:kudipay/core/app/app_routes.dart';

/// Clears the stack and navigates to the main bottom-navigation shell.
void navigateToMainShell(BuildContext context) {
  Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRoutes.bottomNav, (_) => false);
}

/// Widget that redirects to [AppRoutes.bottomNav] on first frame.
class MainShellRedirect extends StatefulWidget {
  const MainShellRedirect({super.key});

  @override
  State<MainShellRedirect> createState() => _MainShellRedirectState();
}

class _MainShellRedirectState extends State<MainShellRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigateToMainShell(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
