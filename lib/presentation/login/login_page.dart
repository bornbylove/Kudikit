import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/presentation/kyc/kyc_flow_manager.dart';
import 'package:kudipay/presentation/linkdevice/link_device_screen.dart';
import 'package:kudipay/presentation/linkdevice/sign_in_verify_email_screen.dart';
import 'package:kudipay/presentation/login/forgot_passcode_screen.dart';
import 'package:kudipay/presentation/signup/signup.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/services/api_services.dart';
import 'package:kudipay/services/biometric_service.dart';
import 'package:kudipay/services/storage_services.dart';

// =============================================================================
// storedUserProvider
// =============================================================================
final storedUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  return StorageService.instance.getUserModel();
});

// =============================================================================
// LoginPage
// =============================================================================
class LoginPage extends ConsumerStatefulWidget {
  final String? email;
  final String? phoneNumber;

  /// Prompt for biometrics as soon as the page opens (PRD login AC 2a). Pass
  /// false when the user has just deliberately signed out — re-prompting them
  /// immediately would be hostile — the "Log in with biometrics" button is
  /// still there.
  final bool autoPromptBiometric;

  const LoginPage({
    this.email,
    this.phoneNumber,
    this.autoPromptBiometric = true,
    super.key,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _identifierCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _showingPhone = true;
  bool _isLoading = false;
  // True once the user has typed into the identifier field directly — stops
  // the stored-value autofill from clobbering what they're typing.
  bool _identifierEdited = false;

  final ValueNotifier<String?> _errorNotifier = ValueNotifier<String?>(null);
  // Drives the Continue button — true only when the password field has text.
  final ValueNotifier<bool> _passwordNotEmpty = ValueNotifier<bool>(false);
  ProviderSubscription<AsyncValue<bool>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
    _setupConnectivityListener();
    // Prefer whichever identifier was actually passed in — defaulting to
    // "phone" when nothing is available yet still leaves an email-only
    // caller (e.g. Signup, which only passes `email:`) blank until
    // _syncIdentifierFromUser corrects it once storedUserProvider resolves.
    _showingPhone = _hasPhone(null) || !_hasEmail(null);
    _identifierCtrl.text = _displayValue(null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareBiometricLogin());
  }

  // ---------------------------------------------------------------------------
  // Biometric login
  // ---------------------------------------------------------------------------
  // Offered only when biometrics are on, this device can prompt for them, and
  // a credential from an earlier successful login is stored (see
  // StorageService.saveBiometricCredential). A successful prompt replays that
  // credential through the ordinary login path, so the server still decides.
  bool _biometricReady = false;
  bool _biometricPrompting = false;

  Future<void> _prepareBiometricLogin() async {
    final storage = StorageService.instance;
    final enabled = await storage.isBiometricEnabled();
    final credential = enabled ? await storage.getBiometricCredential() : null;
    if (credential == null || !mounted) return;

    final availability =
        await ref.read(biometricServiceProvider).checkAvailability();
    if (availability != BiometricAvailability.available || !mounted) return;

    setState(() => _biometricReady = true);
    if (widget.autoPromptBiometric && ref.read(currentConnectivityProvider)) {
      await _loginWithBiometrics();
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (_isLoading || _biometricPrompting) return;
    if (!ref.read(currentConnectivityProvider)) {
      ConnectivitySnackBar.showNoInternet(context);
      return;
    }
    setState(() => _biometricPrompting = true);
    BiometricCredential? credential;
    try {
      await ref
          .read(biometricServiceProvider)
          .authenticate(reason: 'Log in to Kudikit');
      credential = await StorageService.instance.getBiometricCredential();
    } on BiometricAuthException catch (e) {
      // Cancelled or failed — the passcode form is right there. Only surface
      // genuine failures, not the user backing out of the prompt.
      if (mounted && !e.userCancelled) _errorNotifier.value = e.message;
    } finally {
      if (mounted) setState(() => _biometricPrompting = false);
    }
    if (credential == null || !mounted) return;

    _identifierCtrl.text = credential.identifier;
    _identifierEdited = true;
    await _performLogin(
      identifier: credential.identifier,
      password: credential.passcode,
      fromBiometric: true,
    );
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _passwordCtrl.dispose();
    _identifierCtrl.dispose();
    _errorNotifier.dispose();
    _passwordNotEmpty.dispose();
    _connectivitySubscription?.close();
    super.dispose();
  }

  // Autofills the identifier field from the stored user once it resolves,
  // unless the user has already started typing their own value.
  void _syncIdentifierFromUser(UserModel? user) {
    if (_identifierEdited) return;
    _showingPhone = _hasPhone(user) || !_hasEmail(user);
    final value = _displayValue(user);
    if (_identifierCtrl.text != value) {
      _identifierCtrl.text = value;
    }
  }

  void _onPasswordChanged() {
    // Clear the error as soon as the user starts typing again.
    if (_errorNotifier.value != null) {
      _errorNotifier.value = null;
    }
    // Keep the button state in sync with whether there is any text.
    _passwordNotEmpty.value = _passwordCtrl.text.isNotEmpty;
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = ref.listenManual(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        final wasConnected = previous?.value ?? true;
        if (wasConnected && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
          _passwordCtrl.clear();
          _errorNotifier.value = null;
        } else if (!wasConnected && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  String _formatPhone(String raw) {
    if (raw.startsWith('+234') && raw.length >= 13) {
      return '0${raw.substring(4)}';
    }
    return raw;
  }

  String _displayValue(UserModel? user) {
    if (_showingPhone) {
      final raw = widget.phoneNumber ?? user?.phoneNumber ?? '';
      return raw.isEmpty ? '' : _formatPhone(raw);
    }
    final email = widget.email ?? user?.email ?? '';
    return email;
  }

  bool _hasPhone(UserModel? user) =>
      (widget.phoneNumber ?? user?.phoneNumber ?? '').isNotEmpty;

  bool _hasEmail(UserModel? user) =>
      (widget.email ?? user?.email ?? '').isNotEmpty;

  Future<void> _handleLogin(UserModel? user) async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      ConnectivitySnackBar.showNoInternet(context);
      return;
    }

    final identifier = _identifierCtrl.text.trim();
    if (identifier.isEmpty) {
      _errorNotifier.value = _showingPhone
          ? 'Please enter your phone number'
          : 'Please enter your email';
      return;
    }

    final password = _passwordCtrl.text.trim();
    if (password.isEmpty) {
      _errorNotifier.value = 'Please enter your passcode';
      return;
    }

    if (password.length < 6) {
      _errorNotifier.value = 'Passcode must be at least 6 digits';
      return;
    }

    await _performLogin(identifier: identifier, password: password);
  }

  Future<void> _performLogin({
    required String identifier,
    required String password,
    bool fromBiometric = false,
  }) async {
    if (mounted) setState(() => _isLoading = true);
    _errorNotifier.value = null;

    try {
      // The server is authoritative for passcode correctness — a stale or
      // absent local passcode hash (fresh install, new device, reinstall)
      // must never block a login attempt that the backend would accept.
      await ref.read(authProvider.notifier).login(
            email: identifier,
            password: password,
          );

      if (!mounted) return;

      // 202 DEVICE_LINK challenge: this device isn't trusted yet. The OTP was
      // already dispatched by login() itself — route into the existing
      // device-verification flow (reused as-is) instead of the home screen.
      final authState = ref.read(authProvider);
      if (authState.requiresDeviceVerification) {
        final challenge = authState.deviceChallenge!;
        ref.read(deviceLinkingProvider.notifier).startDeviceVerification(
              otpReference: challenge.otpReference,
              identifier: identifier,
              maskedIdentifier: challenge.maskedIdentifier,
            );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => SignInVerifyEmailScreen(
              maskedEmail: challenge.maskedIdentifier,
            ),
          ),
          (_) => false,
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const KycFlowManager()),
        (_) => false,
      );
    } on NoInternetException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on KudiNetworkException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on KudiApiException catch (e) {
      // Clear the field FIRST: _onPasswordChanged wipes any visible error the
      // moment the passcode text changes, so setting the message before
      // clear() erased it in the same frame and users never saw why the
      // login failed (wrong passcode, inactive account, locked out).
      _passwordCtrl.clear();
      _errorNotifier.value = e.message;
      if (fromBiometric && e.statusCode == 401) {
        // The stored passcode no longer works (changed elsewhere, or the
        // account is inactive). Drop it so biometrics can't keep replaying a
        // wrong passcode — every failed attempt counts toward the server's
        // lockout — and let the next passcode login capture a fresh one.
        await StorageService.instance.deleteBiometricCredential();
        if (mounted) setState(() => _biometricReady = false);
      }
    } on TimeoutException catch (e) {
      _errorNotifier.value = e.toString();
    } catch (e) {
      _errorNotifier.value = 'Login failed. Please try again.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Dropdown menu — opens BELOW the identifier field when the chevron is tapped.
  // Uses a GlobalKey on the field to measure its exact screen position and
  // anchor the menu flush to its bottom edge.
  // ---------------------------------------------------------------------------
  final _identifierFieldKey = GlobalKey();

  // Cached so _showIdentifierMenu can read connectivity without a BuildContext arg.
  bool _isOnlineCached = true;

  void _showIdentifierMenu(UserModel? user) {
    if (!_isOnlineCached) return;

    final phone = widget.phoneNumber ?? user?.phoneNumber ?? '';
    final email = widget.email ?? user?.email ?? '';

    final box =
        _identifierFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    // Anchor the menu top-left to the bottom-left of the identifier field.
    final fieldBottomLeft =
        box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);

    final position = RelativeRect.fromLTRB(
      fieldBottomLeft.dx,
      fieldBottomLeft.dy,
      overlay.size.width - fieldBottomLeft.dx - box.size.width,
      0,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
      ),
      items: [
        if (phone.isNotEmpty)
          _menuItem(context,
              value: 'phone',
              icon: Icons.person_outline_rounded,
              label: _formatPhone(phone),
              selected: _showingPhone),
        if (email.isNotEmpty)
          _menuItem(context,
              value: 'email',
              icon: Icons.email_outlined,
              label: email,
              selected: !_showingPhone),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      setState(() {
        _showingPhone = value == 'phone';
        _errorNotifier.value = null;
        _identifierEdited = false;
        _identifierCtrl.text = _displayValue(user);
      });
    });
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    const brand = Color(0xFF069494);
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppLayout.scaleWidth(context, 18),
            color: selected ? brand : Colors.grey[500],
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? brand : const Color(0xFF171515),
              ),
            ),
          ),
          if (selected) ...[
            SizedBox(width: AppLayout.scaleWidth(context, 8)),
            Icon(Icons.check_rounded,
                size: AppLayout.scaleWidth(context, 16), color: brand),
          ],
        ],
      ),
    );
  }

  Future<void> _openForgotPasscode() async {
    final didReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasscodeScreen(initialIdentifier: _identifierCtrl.text),
      ),
    );
    if (didReset != true || !mounted) return;
    // The reset revoked every session and any stored biometric credential is
    // now stale — make the next step obvious.
    _passwordCtrl.clear();
    _errorNotifier.value = null;
    setState(() => _biometricReady = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passcode updated. Log in with your new passcode.'),
        backgroundColor: Color.fromARGB(255, 6, 148, 42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;
    final userAsync = ref.watch(storedUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              _OfflineBanner(
                onRetry: () =>
                    ref.read(connectivityStateProvider.notifier).refresh(),
              ),
            SizedBox(width: AppLayout.scaleWidth(context, 50)),
            Expanded(
              child: userAsync.when(
                loading: () => _buildBody(context, null, isOnline),
                error: (_, __) => _buildBody(context, null, isOnline),
                data: (user) {
                  _syncIdentifierFromUser(user);
                  return _buildBody(context, user, isOnline);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserModel? user, bool isOnline) {
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final bannerH = isOnline ? 0.0 : AppLayout.scaleHeight(context, 42);
    final canToggle = _hasPhone(user) && _hasEmail(user);

    // Keep the cached connectivity flag in sync so _showIdentifierMenu can read it.
    _isOnlineCached = isOnline;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenH - topPad - bannerH),
        child: IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppLayout.scaleHeight(context, 23)),

                // ── Top bar ──────────────────────────────────────────────
                _TopBar(isOnline: isOnline),

                SizedBox(height: AppLayout.scaleHeight(context, 150)),

                // ── Heading ──────────────────────────────────────────────
                Text(
                  'Login into your Kudikit Account',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 26),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF171515),
                    height: 1.25,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // ── Identifier field ──────────────────────────────────────
                // Editable, pre-filled from the stored user (or route args).
                // The chevron (shown only when both phone and email are on
                // file) opens a dropdown anchored below this field to switch
                // which one is prefilled — typing directly always wins.
                _IdentifierField(
                  key: _identifierFieldKey,
                  controller: _identifierCtrl,
                  showingPhone: _showingPhone,
                  canToggle: canToggle,
                  enabled: !_isLoading && isOnline,
                  onChanged: (_) => _identifierEdited = true,
                  onToggleTap: () => _showIdentifierMenu(user),
                ),

                // ── Error message — directly below identifier field ────────
                ValueListenableBuilder<String?>(
                  valueListenable: _errorNotifier,
                  builder: (context, errorText, _) {
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      child: errorText != null
                          ? Padding(
                              padding: EdgeInsets.only(
                                top: AppLayout.scaleHeight(context, 8),
                                left: AppLayout.scaleWidth(context, 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: AppLayout.scaleWidth(context, 14),
                                    color: const Color(0xFFE53935),
                                  ),
                                  SizedBox(
                                      width: AppLayout.scaleWidth(context, 4)),
                                  Expanded(
                                    child: Text(
                                      errorText,
                                      style: TextStyle(
                                        fontSize:
                                            AppLayout.fontSize(context, 13),
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFFE53935),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 12)),

                // ── Password field ────────────────────────────────────────
                _PasswordField(
                  controller: _passwordCtrl,
                  visible: _passwordVisible,
                  enabled: !_isLoading && isOnline,
                  onToggleVisibility: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  onSubmitted: () => _handleLogin(user),
                ),

                // ── Forgot passcode ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isOnline ? _openForgotPasscode : null,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 8),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Passcode?',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? const Color(0xFF069494)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // ── Continue button ───────────────────────────────────────
                _ContinueButton(
                  isLoading: _isLoading,
                  isOnline: isOnline,
                  passwordNotEmpty: _passwordNotEmpty,
                  onPressed: () => _handleLogin(user),
                ),

                // ── Biometric login ───────────────────────────────────────
                if (_biometricReady)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: (isOnline && !_isLoading && !_biometricPrompting)
                          ? _loginWithBiometrics
                          : null,
                      icon: const Icon(Icons.fingerprint,
                          color: Color(0xFF069494)),
                      label: Text(
                        'Log in with biometrics',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? const Color(0xFF069494)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // ── Sign-up row ───────────────────────────────────────────
                _SignUpRow(isOnline: isOnline),

                SizedBox(height: AppLayout.scaleHeight(context, 40)),

                // ── CBN / NDIC footer ─────────────────────────────────────
                const _LicensingFooter(),
                SizedBox(height: AppLayout.scaleHeight(context, 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Top bar
// =============================================================================
class _TopBar extends ConsumerWidget {
  final bool isOnline;
  const _TopBar({required this.isOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: AppLayout.scaleWidth(context, 30),
          height: AppLayout.scaleWidth(context, 30),
          child: Image.asset(
            'assets/images/Kudikit_teal_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => CustomPaint(
              painter: _KudiKitLogoPainter(),
            ),
          ),
        ),
        GestureDetector(
          onTap: isOnline
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkDeviceScreen()),
                  )
              : () => ConnectivitySnackBar.showNoInternet(context),
          child: Text(
            'Link new device',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w500,
              color: isOnline ? const Color(0xFF069494) : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Identifier field — read-only display
// =============================================================================
class _IdentifierField extends StatelessWidget {
  final TextEditingController controller;
  final bool showingPhone;
  final bool canToggle;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleTap;

  const _IdentifierField({
    super.key,
    required this.controller,
    required this.showingPhone,
    required this.canToggle,
    required this.enabled,
    required this.onChanged,
    required this.onToggleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFCEE5D8), width: 1),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType:
            showingPhone ? TextInputType.phone : TextInputType.emailAddress,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 15),
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          hintText: showingPhone ? 'Phone number' : 'Email address',
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: AppLayout.scaleWidth(context, 16),
              right: AppLayout.scaleWidth(context, 10),
            ),
            child: Icon(
              showingPhone
                  ? Icons.person_outline_rounded
                  : Icons.email_outlined,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 15),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          // Chevron — only shown when toggling between phone/email is possible.
          suffixIcon: canToggle
              ? IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                    size: AppLayout.scaleWidth(context, 22),
                  ),
                  splashRadius: AppLayout.scaleWidth(context, 18),
                  onPressed: onToggleTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 17),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Password field
// =============================================================================
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final bool enabled;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.enabled,
    required this.onToggleVisibility,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFD6EAE0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmitted(),
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 15),
          fontWeight: FontWeight.w500,
          color: const Color(0xFF171515),
        ),
        decoration: InputDecoration(
          hintText: 'Passcode',
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: AppLayout.scaleWidth(context, 16),
              right: AppLayout.scaleWidth(context, 10),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 15),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: IconButton(
            icon: Icon(
              visible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 20),
            ),
            splashRadius: AppLayout.scaleWidth(context, 18),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 17),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Continue button
// =============================================================================
class _ContinueButton extends StatelessWidget {
  final bool isLoading;
  final bool isOnline;
  final ValueNotifier<bool> passwordNotEmpty;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isLoading,
    required this.isOnline,
    required this.passwordNotEmpty,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds only this button on each keystroke,
    // leaving the rest of the form untouched.
    return ValueListenableBuilder<bool>(
      valueListenable: passwordNotEmpty,
      builder: (context, hasText, _) {
        final disabled = isLoading || !isOnline || !hasText;
        return SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 54),
          child: ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF069494),
              disabledBackgroundColor: const Color(0xFF069494).withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 32)),
              ),
            ),
            child: isLoading
                ? const AppLoadingIndicator.button()
                : Text(
                    isOnline ? 'Continue' : 'No Internet Connection',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}


// =============================================================================
// Sign-up row
// =============================================================================
class _SignUpRow extends StatelessWidget {
  final bool isOnline;
  const _SignUpRow({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF171515)),
          ),
          GestureDetector(
            onTap: isOnline
                ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    )
                : null,
            child: Text(
              'Sign up',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: isOnline ? const Color(0xFF069494) : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Offline banner
// =============================================================================
class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: EdgeInsets.symmetric(
        vertical: AppLayout.scaleHeight(context, 8),
        horizontal: AppLayout.scaleWidth(context, 16),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off,
              color: Colors.white, size: AppLayout.scaleWidth(context, 18)),
          SizedBox(width: AppLayout.scaleWidth(context, 8)),
          Expanded(
            child: Text(
              'No internet — Login requires a connection',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: AppLayout.fontSize(context, 13)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 8)),
            ),
            child: Text('Retry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CBN / NDIC licensing footer
// =============================================================================
class _LicensingFooter extends StatelessWidget {
  const _LicensingFooter();

  @override
  Widget build(BuildContext context) {
    final iconH = AppLayout.scaleWidth(context, 20);
    final fs = AppLayout.fontSize(context, 11);

    return Center(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 8)),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            SizedBox(
              width: iconH,
              height: iconH,
              child: Image.asset(
                'assets/images/cbn.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.account_balance,
                    size: iconH * 0.75, color: Colors.grey[600]),
              ),
            ),
            Text('Licensed by the ',
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: fs,
                    fontWeight: FontWeight.w400)),
            Text('CBN',
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: fs,
                    fontWeight: FontWeight.bold)),
            Text(' and insured by the',
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: fs,
                    fontWeight: FontWeight.w400)),
            SizedBox(
              height: iconH,
              child: Image.asset(
                'assets/images/ndicc.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.account_balance,
                    size: iconH * 0.75, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _KudiKitLogoPainter — fallback only
// =============================================================================
class _KudiKitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF389165)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.drawPath(
        Path()
          ..moveTo(w * 0.14, h * 0.22)
          ..lineTo(w * 0.40, h * 0.50)
          ..lineTo(w * 0.14, h * 0.78),
        p);

    canvas.drawPath(
        Path()
          ..moveTo(w * 0.42, h * 0.22)
          ..lineTo(w * 0.68, h * 0.50)
          ..lineTo(w * 0.42, h * 0.78),
        p);
  }

  @override
  bool shouldRepaint(_KudiKitLogoPainter _) => false;
}