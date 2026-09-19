// lib/presentation/lock/app_lock_screen.dart
// PRD §2.1.5.3/§2.1.5.4: the re-entry gate shown on cold start with a cached
// session, and whenever the inactivity timer (session_lock_provider.dart)
// fires. Tries biometrics first when enrolled, always offers the passcode
// fallback ("Fallback: Always show passcode fallback option").
//
// Unlocking here never calls the network — it verifies the entered passcode
// against the locally-stored salted hash (StorageService.verifyPasscode),
// the same one set during onboarding/PIN creation. The cached session
// token itself is untouched; this screen only gates the UI in front of it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/root_navigator.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/passcode/numeric_keypad.dart';
import 'package:kudipay/presentation/passcode/passcode_dots.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart';
import 'package:kudipay/provider/auth/session_lock_provider.dart';
import 'package:kudipay/services/biometric_service.dart';
import 'package:kudipay/services/storage_services.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  String _passcode = '';
  String? _error;
  bool _checkingBiometric = false;

  static const _passcodeMaxLength = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-offer biometrics if the user backgrounds the app (e.g. to open
    // their fingerprint settings) and comes straight back to this screen.
    if (state == AppLifecycleState.resumed && mounted) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_checkingBiometric) return;
    final enabled = await StorageService.instance.isBiometricEnabled();
    if (!enabled || !mounted) return;

    final availability =
        await ref.read(biometricServiceProvider).checkAvailability();
    if (availability != BiometricAvailability.available || !mounted) return;

    setState(() => _checkingBiometric = true);
    try {
      await ref.read(biometricServiceProvider).authenticate(
            reason: 'Unlock Kudikit',
          );
      if (!mounted) return;
      ref.read(sessionLockProvider.notifier).unlock();
    } on BiometricAuthException {
      // Cancelled or failed — fall through to the passcode keypad silently,
      // the PRD's "always show passcode fallback" already means this screen
      // stays visible either way.
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  bool _verifying = false;

  void _onDigit(String digit) {
    if (_passcode.length >= _passcodeMaxLength) return;
    setState(() {
      _passcode += digit;
      _error = null;
    });
    // Passcodes are 6-8 digits (PRD §2.1.5.1) — only the max length can be
    // auto-submitted with certainty; 6 and 7-digit passcodes are confirmed
    // via the explicit "Unlock" button below (same pattern as the network
    // login's Continue button — never guess where a variable-length code
    // ends).
    if (_passcode.length == _passcodeMaxLength) _submitPasscode();
  }

  void _onBackspace() {
    if (_passcode.isEmpty) return;
    setState(() {
      _passcode = _passcode.substring(0, _passcode.length - 1);
      _error = null;
    });
  }

  Future<void> _submitPasscode() async {
    if (_passcode.length < 6 || _verifying) return;
    setState(() => _verifying = true);
    final ok = await StorageService.instance.verifyPasscode(_passcode);
    if (!mounted) return;
    if (ok) {
      // The plaintext passcode is in hand and matches what the server last
      // accepted: if biometrics were switched on after the last login (so no
      // credential was captured then), capture it now.
      final user = ref.read(currentUserProvider);
      final identifier = user == null
          ? ''
          : (user.email.isNotEmpty ? user.email : user.phoneNumber);
      if (identifier.isNotEmpty) {
        await ref.read(authProvider.notifier).rememberBiometricCredential(
              identifier: identifier,
              passcode: _passcode,
            );
      }
      if (!mounted) return;
      ref.read(sessionLockProvider.notifier).unlock();
      return;
    }
    setState(() {
      _verifying = false;
      _error = 'Incorrect passcode';
      _passcode = '';
    });
  }

  // Escape hatch. The unlock passcode is checked against a hash kept on this
  // device, so it can be missing or stale (new-device login, passcode reset on
  // another device) — without a way out the user is stuck behind this screen.
  // Signing out returns them to LoginPage, which checks against the server and
  // offers the forgot-passcode reset.
  //
  // The confirmation is inline rather than a dialog: this screen is drawn
  // above the whole Navigator (MaterialApp.builder), so a dialog pushed onto
  // the Navigator would open underneath it and never be seen.
  bool _confirmingSignOut = false;

  Future<void> _signInAgain() async {
    await ref.read(authProvider.notifier).logout();
    ref.read(sessionLockProvider.notifier).disarm();
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => const LoginPage(autoPromptBiometric: false)),
      (_) => false,
    );
  }

  Widget _buildForgotPasscode(BuildContext context) {
    if (!_confirmingSignOut) {
      return TextButton(
        onPressed: () => setState(() => _confirmingSignOut = true),
        child: Text(
          'Forgot passcode?',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Column(
      children: [
        Text(
          'You\'ll be signed out on this device. Log in again with your '
          'passcode, or reset it from the login screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _confirmingSignOut = false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _signInAgain,
              child: const Text(
                'Sign out',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final identifier = user?.email.isNotEmpty == true
        ? user!.email
        : (user?.phoneNumber ?? '');

    return PopScope(
      // A locked app must not be dismissed with the back button — that
      // would leave the underlying (unlocked) screen visible.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 24)),
            child: Column(
              children: [
                SizedBox(height: AppLayout.scaleHeight(context, 48)),
                Container(
                  width: AppLayout.scaleWidth(context, 72),
                  height: AppLayout.scaleWidth(context, 72),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: AppColors.primaryTeal,
                      size: AppLayout.scaleWidth(context, 36)),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 20)),
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (identifier.isNotEmpty) ...[
                  SizedBox(height: AppLayout.scaleHeight(context, 6)),
                  Text(
                    identifier,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                SizedBox(height: AppLayout.scaleHeight(context, 32)),
                PasscodeDotsIndicator(
                  length: _passcode.length < 6 ? 6 : _passcode.length,
                  filledCount: _passcode.length,
                  showError: _error != null,
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                SizedBox(
                  height: AppLayout.scaleHeight(context, 20),
                  child: Text(
                    _error ?? 'Enter your passcode to unlock',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: _error != null
                          ? const Color(0xFFE53935)
                          : AppColors.textGrey,
                    ),
                  ),
                ),
                // Passcodes are 6-8 digits — once 6+ are entered the user may
                // have finished (a 6- or 7-digit passcode) or may keep
                // typing; offer an explicit way to submit rather than
                // guessing, matching login_page.dart's Continue button.
                if (_passcode.length >= 6 && _passcode.length < _passcodeMaxLength) ...[
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  TextButton(
                    onPressed: _verifying ? null : _submitPasscode,
                    child: Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                NumericKeypad(
                  onNumberPressed: _onDigit,
                  onBackspacePressed: _onBackspace,
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
                FutureBuilder<bool>(
                  future: StorageService.instance.isBiometricEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return TextButton.icon(
                      onPressed: _checkingBiometric ? null : _tryBiometric,
                      icon: const Icon(Icons.fingerprint,
                          color: AppColors.primaryTeal),
                      label: Text(
                        'Use biometrics',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                _buildForgotPasscode(context),
                SizedBox(height: AppLayout.scaleHeight(context, 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
