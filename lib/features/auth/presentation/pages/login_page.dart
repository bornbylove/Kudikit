import 'dart:async';
import 'package:kudipay/core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/link_device_screen.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/api_services.dart';
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

  const LoginPage({this.email, this.phoneNumber, super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _showingPhone = true;
  bool _isLoading = false;

  final ValueNotifier<String?> _errorNotifier = ValueNotifier<String?>(null);
  // Drives the Continue button — true only when the password field has text.
  final ValueNotifier<bool> _passwordNotEmpty = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _passwordCtrl.dispose();
    _errorNotifier.dispose();
    _passwordNotEmpty.dispose();
    super.dispose();
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
    ref.listen(connectivityProvider, (previous, next) {
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
      return raw.isEmpty ? '—' : _formatPhone(raw);
    }
    final email = widget.email ?? user?.email ?? '';
    return email.isEmpty ? '—' : email;
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

    final password = _passwordCtrl.text.trim();
    if (password.isEmpty) {
      _errorNotifier.value = 'Please enter your passcode';
      return;
    }

    if (password.length < 8) {
      _errorNotifier.value = 'Passcode must be at least 8 characters';
      return;
    }

    // Build the identifier from whichever field is currently shown
    final identifier = _showingPhone
        ? (widget.phoneNumber ?? user?.phoneNumber ?? '')
        : (widget.email ?? user?.email ?? ref.read(userEmailProvider) ?? '');

    if (identifier.isEmpty) {
      _errorNotifier.value = 'No account found on this device. Please sign up.';
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    _errorNotifier.value = null;

    try {
      await ref.read(authProvider.notifier).login(
            email: identifier, // field is named email but accepts phone too
            password: password,
          );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.bottomNav, (_) => false);
    } on NoInternetException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      _errorNotifier.value = e.toString();
    } catch (e) {
      _errorNotifier.value = e.toString().replaceFirst('Exception: ', '');
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
    const brand = AppColors.primaryTeal;
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

  void _showForgotPinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPinSheet(),
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
                data: (user) => _buildBody(context, user, isOnline),
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
                // Tapping the field (or the chevron) opens a dropdown menu
                // anchored below this field listing phone and email options.
                _IdentifierField(
                  key: _identifierFieldKey,
                  displayValue: _displayValue(user),
                  showingPhone: _showingPhone,
                  canToggle: canToggle,
                  onTap: () => _showIdentifierMenu(user),
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

                // ── Forgot PIN ────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isOnline ? _showForgotPinSheet : null,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 8),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot PIN',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color:
                            isOnline ? AppColors.primaryTeal : Colors.grey[400],
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
              color: isOnline ? AppColors.primaryTeal : Colors.grey[400],
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
  final String displayValue;
  final bool showingPhone;
  final bool canToggle;
  final VoidCallback onTap;

  const _IdentifierField({
    super.key,
    required this.displayValue,
    required this.showingPhone,
    required this.canToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canToggle ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 17),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(color: const Color(0xFFCEE5D8), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              showingPhone
                  ? Icons.person_outline_rounded
                  : Icons.email_outlined,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 15),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 10)),
            Expanded(
              child: Text(
                displayValue,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            // Chevron — only shown when toggling between phone/email is possible.
            if (canToggle) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 4)),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
                size: AppLayout.scaleWidth(context, 22),
              ),
            ],
          ],
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
              backgroundColor: AppColors.primaryTeal,
              disabledBackgroundColor:
                  AppColors.primaryTeal.withValues(alpha: 0.5),
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
                ? () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.signup)
                : null,
            child: Text(
              'Sign up',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: isOnline ? AppColors.primaryTeal : Colors.grey[400],
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
// Forgot PIN bottom sheet
// =============================================================================
class _ForgotPinSheet extends StatelessWidget {
  const _ForgotPinSheet();

  @override
  Widget build(BuildContext context) {
    const brand = AppColors.primaryTeal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 32),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Container(
              width: AppLayout.scaleWidth(context, 64),
              height: AppLayout.scaleWidth(context, 64),
              decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.lock_reset_rounded,
                  color: brand, size: AppLayout.scaleWidth(context, 32)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text('Forgot PIN?',
                style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Text(
              'To reset your PIN, log in using your email and '
              'create a new one, or contact our support team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600],
                  height: 1.5),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 28)),
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 52),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.lock_reset,
                                  color: brand, size: 28),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'PIN Reset via Email',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Self-service PIN reset via email is coming soon. '
                              'For now, contact our support team to reset your PIN.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9E9E9E),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                      context, AppRoutes.support);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brand,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Text(
                                  'Contact Support',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 32))),
                ),
                child: Text('Reset via Email',
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 52),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brand, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 32))),
                ),
                child: Text('Cancel',
                    style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: brand)),
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
