// lib/features/auth/presentation/pages/reset_passcode.dart
//
// Step 3 of 3 — sets the new passcode against a verified otpReference.
//
// Entry is delegated to PasscodeSetupScreen so the reset flow uses exactly the
// same keypad, digit count and confirm behaviour as signup. This screen only
// owns the API call and where to go afterwards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/passcode/presentation/pages/passcode_setup_screen.dart';

class ResetPasscodeScreen extends ConsumerWidget {
  final String otpReference;

  const ResetPasscodeScreen({super.key, required this.otpReference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PasscodeSetupScreen(
      title: 'Create a new passcode',
      onSubmit: (passcode) async {
        // Both entries already matched on the keypad; the server re-checks.
        await ref.read(resetPasscodeUseCaseProvider).call(
              otpReference: otpReference,
              newPasscode: passcode,
              confirmPasscode: passcode,
            );

        if (!context.mounted) return;
        // The reset clears any stored session, so return to a clean login
        // rather than leaving the reset flow on the stack.
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passcode updated. Please log in.'),
            backgroundColor: Color.fromARGB(255, 6, 148, 42),
          ),
        );
      },
    );
  }
}
