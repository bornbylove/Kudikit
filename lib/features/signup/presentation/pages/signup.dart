import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/passcode.dart';
import 'package:kudipay/core/utils/phone_number.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/passcode/presentation/pages/passcode_setup_screen.dart';
import 'package:kudipay/shared/widgets/color_app_button.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/features/signup/presentation/pages/signup_more_details.dart';
import 'package:flutter_riverpod/legacy.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

// ? Top-level � lives outside any class, at file scope

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // now ref.watch(_termsAcceptedProvider) works correctly

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  // ---------------------------------------------------------------------------
  // FORM KEY � still used to trigger _validate() on submit
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // PER-FIELD ERROR STRINGS

  String? _emailError;
  String? _phoneError;
  String? _passcodeError;

  // ---------------------------------------------------------------------------
  // LOCAL TERMS ACCEPTANCE STATE
  // ---------------------------------------------------------------------------

  final _termsAcceptedProvider = StateProvider<bool>((ref) => false);

  // ---------------------------------------------------------------------------
  // PASSCODE
  // ---------------------------------------------------------------------------

  /// Set by PasscodeSetupScreen once both entries match. Null until then.
  String? _passcode;

  Future<void> _openPasscodeSetup() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PasscodeSetupScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _passcode = result;
      _passcodeError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // SUBMIT READINESS
  // ---------------------------------------------------------------------------

  bool get _fieldsReady =>
      emailController.text.trim().isNotEmpty &&
      normalizeNigerianPhone(numberController.text) != null &&
      _passcode != null;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    emailController.addListener(_onFieldChanged);
    numberController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    emailController.removeListener(_onFieldChanged);
    numberController.removeListener(_onFieldChanged);
    emailController.dispose();
    numberController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CONNECTIVITY LISTENER
  // ---------------------------------------------------------------------------

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        final wasConnected = previous?.value ?? true;
        if (wasConnected && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (!wasConnected && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // FIELD-LEVEL VALIDATION
  // ---------------------------------------------------------------------------

  bool _validateFields() {
    bool valid = true;
    setState(() {
      // Email
      final email = emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
        valid = false;
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Please enter a valid email address';
        valid = false;
      } else {
        _emailError = null;
      }

      // Phone — accepts 07015697383, 7015697383 or +2347015697383.
      _phoneError = nigerianPhoneError(numberController.text);
      if (_phoneError != null) valid = false;

      // Passcode — set via PasscodeSetupScreen, which also confirms it.
      _passcodeError =
          _passcode == null ? 'Set a $kPasscodeLength-digit passcode' : null;
      if (_passcodeError != null) valid = false;
    });
    return valid;
  }

  // ---------------------------------------------------------------------------
  // HANDLE SIGN UP
  // ---------------------------------------------------------------------------

  Future<void> _handleSignUp() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    if (!_validateFields()) return;

    final termsAccepted = ref.read(_termsAcceptedProvider);
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: AppColors.avatarRed,
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    // Non-null: _validateFields() above rejects anything unnormalisable.
    final phoneNumber = normalizeNigerianPhone(numberController.text)!;
    // Non-null: _validateFields() rejects a null passcode above.
    final passcode = _passcode!;

    try {
      // The referral code is collected on the next screen and can only be sent
      // with /auth/register, so the OTP is not requested until that screen's
      // Continue — that also keeps the 5-minute OTP window from being spent
      // while the user fills in the form.
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KnowYouBetterForm(
            email: email,
            phoneNumber: phoneNumber,
            passcode: passcode,
            confirmPasscode: passcode,
          ),
        ),
      );
    } on NoInternetException {
      if (!mounted) return;
      ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.avatarOrange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: AppColors.avatarRed,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    final isLoading = authState.isLoading;
    final isOnline = connectivityState.isConnected;
    final termsAccepted = ref.watch(_termsAcceptedProvider);
    final canSubmit = _fieldsReady && termsAccepted;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context, isOnline),
      body: Column(
        children: [
          if (!isOnline) _buildOfflineBanner(context),
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                // Form is kept so the GlobalKey is valid, but we don't
                // rely on its built-in validator display anymore.
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: AppLayout.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppLayout.scaleHeight(context, 25)),

                        Text(
                          'Create an account with KudiKit',
                          style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 25),
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              color: AppColors.textDark),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 25)),

                        // -- Email ------------------------------------------
                        _buildLabel(context, 'Email'),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        _buildPlainField(
                          context,
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading && isOnline,
                          hasError: _emailError != null,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                        // ERROR BELOW FIELD
                        _buildFieldError(_emailError),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // -- Phone Number -----------------------------------
                        _buildLabel(context, 'Phone Number'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildPlainField(
                          context,
                          controller: numberController,
                          prefixText: '+234 ',
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading && isOnline,
                          hasError: _phoneError != null,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            // 11 so a leading 0 fits. At 10 this silently
                            // truncated 07015697383 to 0701569738.
                            LengthLimitingTextInputFormatter(11),
                          ],
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                        ),
                        // ERROR BELOW FIELD
                        _buildFieldError(_phoneError),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // -- Passcode ---------------------------------------
                        // Entered on the keypad screen rather than inline: it
                        // is now $kPasscodeLength digits, set and confirmed
                        // via PasscodeSetupScreen.
                        _buildLabel(context, 'Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildPasscodeTile(context, isLoading, isOnline),
                        _buildFieldError(_passcodeError),

                        SizedBox(height: AppLayout.scaleHeight(context, 20)),

                        //  Terms & Conditions Checkbox
                        _buildTermsCheckbox(context, isLoading, isOnline),

                        SizedBox(height: AppLayout.scaleHeight(context, 42)),

                        //  Submit Button
                        _buildSubmitButton(
                            context, isLoading, isOnline, canSubmit),

                        SizedBox(height: AppLayout.scaleHeight(context, 15)),

                        // Already have an account?
                        _buildLoginRow(context, isLoading, isOnline),

                        SizedBox(height: AppLayout.scaleHeight(context, 13)),

                        //  CBN / NDIC Licensing Footer
                        _buildLicensingFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // EXTRACTED WIDGET BUILDERS
  // =============================================================================

  AppBar _buildAppBar(BuildContext context, bool isOnline) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
          size: AppLayout.scaleWidth(context, 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
          child: Center(
            child: Stack(
              children: [
                SizedBox(
                  width: AppLayout.scaleWidth(context, 30),
                  height: AppLayout.scaleWidth(context, 30),
                  child: CircularProgressIndicator(
                    value: 0.12,
                    strokeWidth: AppLayout.scaleWidth(context, 2),
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '12%',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade700,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No internet � Sign up requires a connection',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(connectivityStateProvider.notifier).refresh(),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(
      BuildContext context, bool isLoading, bool isOnline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppLayout.scaleWidth(context, 24),
          height: AppLayout.scaleWidth(context, 24),
          child: Checkbox(
            value: ref.watch(_termsAcceptedProvider),
            onChanged: (isLoading || !isOnline)
                ? null
                : (value) {
                    ref.read(_termsAcceptedProvider.notifier).state =
                        value ?? false;
                  },
            activeColor: AppColors.primaryTeal,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 4)),
            ),
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'I have read, understood and agreed to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    bool isLoading,
    bool isOnline,
    bool canSubmit,
  ) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryTeal,
          strokeWidth: AppLayout.scaleWidth(context, 1),
        ),
      );
    }
    if (!isOnline) {
      return SizedBox(
        width: double.infinity,
        child: Opacity(
          opacity: 0.5,
          child: ColorAppButton(
            press: () => ConnectivitySnackBar.showNoInternet(context),
            text: 'No Internet Connection',
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: canSubmit ? 1.0 : 0.45,
        child: ColorAppButton(
          press: canSubmit ? _handleSignUp : () {},
          text: 'Continue',
        ),
      ),
    );
  }

  Widget _buildLoginRow(BuildContext context, bool isLoading, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        TextButton(
          onPressed: (isLoading || !isOnline)
              ? null
              : () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.login,
                    arguments: LoginArgs(
                      email: emailController.text.trim(),
                    ),
                  );
                },
          child: Text(
            'Log in',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: isOnline ? AppColors.primaryTeal : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensingFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/cbn.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance,
                  size: 20, color: Color(0xFF2C2C2C)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Licensed by the ',
              style: TextStyle(color: Colors.black, fontSize: 12)),
          const Text('CBN',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Text('and insured by the',
              style: TextStyle(color: Colors.black, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Image.asset(
              'assets/images/ndicc.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_balance,
                  size: 20, color: Color(0xFF2C2C2C)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR TEXT
  // ---------------------------------------------------------------------------

  Widget _buildFieldError(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: error != null
          ? Padding(
              padding: EdgeInsets.only(
                top: AppLayout.scaleHeight(context, 5),
                left: AppLayout.scaleWidth(context, 4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppLayout.scaleWidth(context, 13),
                    color: const Color(0xFFE53935),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 4)),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
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
  }

  // ---------------------------------------------------------------------------
  // PASSCODE TILE — opens the keypad, shows whether one has been set
  // ---------------------------------------------------------------------------

  Widget _buildPasscodeTile(
      BuildContext context, bool isLoading, bool isOnline) {
    final isSet = _passcode != null;

    return GestureDetector(
      onTap: (isLoading || !isOnline) ? null : _openPasscodeSetup,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
          border: Border.all(
            color: _passcodeError != null
                ? AppColors.avatarRed
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSet ? Icons.check_circle : Icons.lock_outline,
              size: AppLayout.scaleWidth(context, 20),
              color: isSet ? AppColors.primaryTeal : Colors.grey,
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: Text(
                isSet
                    ? '${'•' * kPasscodeLength}  (tap to change)'
                    : 'Tap to set a $kPasscodeLength-digit passcode',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: isSet ? Colors.black87 : Colors.grey,
                  letterSpacing: isSet ? 2 : 0,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: AppLayout.scaleWidth(context, 14), color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE FIELD BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPlainField(
    BuildContext context, {
    required TextEditingController controller,
    String? prefixText,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    bool hasError = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        // border: hasError
        //     ? Border.all(color: const Color(0xFFE53935), width: 1.2)
        //     : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 15),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            color: Colors.grey[500],
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 12),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
        ),
      ),
    );
  }
}
