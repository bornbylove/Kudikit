import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/color_app_button.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/core/navigation/app_routes.dart';
import 'package:kudipay/features/signup/presentation/pages/signup_verify.dart';
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
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // FORM KEY � still used to trigger _validate() on submit
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // PER-FIELD ERROR STRINGS

  String? _emailError;
  String? _phoneError;
  String? _passcodeError;
  String? _confirmPasscodeError;

  // ---------------------------------------------------------------------------
  // LOCAL TERMS ACCEPTANCE STATE
  // ---------------------------------------------------------------------------

  final _termsAcceptedProvider = StateProvider<bool>((ref) => false);

  // ---------------------------------------------------------------------------
  // PASSCODE CRITERIA STATE
  // ---------------------------------------------------------------------------

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passcodeFieldTouched = false;

  // ---------------------------------------------------------------------------
  // SUBMIT READINESS
  // ---------------------------------------------------------------------------

  bool get _fieldsReady =>
      emailController.text.trim().isNotEmpty &&
      numberController.text.trim().length == 10 &&
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar &&
      confirmPasswordController.text == passwordController.text &&
      confirmPasswordController.text.isNotEmpty;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    emailController.addListener(_onFieldChanged);
    numberController.addListener(_onFieldChanged);
    confirmPasswordController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    emailController.removeListener(_onFieldChanged);
    numberController.removeListener(_onFieldChanged);
    confirmPasswordController.removeListener(_onFieldChanged);
    emailController.dispose();
    numberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
  // PASSCODE CRITERIA UPDATER
  // ---------------------------------------------------------------------------

  void _updatePasscodeCriteria(String value) {
    setState(() {
      _passcodeFieldTouched = value.isNotEmpty;
      _hasMinLength = value.length >= 8 && value.length <= 12;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*]'));
      // Clear the passcode error as the user types
      if (_passcodeError != null) _passcodeError = null;
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

      // Phone
      final phone = numberController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'Please enter your phone number';
        valid = false;
      } else if (phone.length != 10) {
        _phoneError = 'Enter a valid 10-digit Nigerian phone number';
        valid = false;
      } else {
        _phoneError = null;
      }

      // Passcode
      final passcode = passwordController.text;
      if (passcode.isEmpty) {
        _passcodeError = 'Please enter a passcode';
        valid = false;
      } else if (!_hasMinLength) {
        _passcodeError = 'Passcode must be 8�12 characters';
        valid = false;
      } else if (!_hasUppercase) {
        _passcodeError = 'Must contain at least one uppercase letter';
        valid = false;
      } else if (!_hasLowercase) {
        _passcodeError = 'Must contain at least one lowercase letter';
        valid = false;
      } else if (!_hasNumber) {
        _passcodeError = 'Must contain at least one number';
        valid = false;
      } else if (!_hasSpecialChar) {
        _passcodeError =
            'Must contain at least one special character (!@#\$%^&*)';
        valid = false;
      } else {
        _passcodeError = null;
      }

      // Confirm passcode
      final confirm = confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmPasscodeError = 'Please confirm your passcode';
        valid = false;
      } else if (confirm != passwordController.text) {
        _confirmPasscodeError = 'Passcodes do not match';
        valid = false;
      } else {
        _confirmPasscodeError = null;
      }
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
    final phoneNumber = '+234${numberController.text.trim()}';
    final password = passwordController.text.trim();

    try {
      final otpId = await ref.read(authProvider.notifier).sendSignupOtp(
            email: email,
            phoneNumber: phoneNumber,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerifySignup(
            email: email,
            phoneNumber: phoneNumber,
            passcode: password,
            otpId: otpId,
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
                            LengthLimitingTextInputFormatter(10),
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
                        _buildLabel(context, 'Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildPlainField(
                          context,
                          controller: passwordController,
                          obscureText: !ref.watch(pinVisibilityProvider),
                          enabled: !isLoading && isOnline,
                          hasError: _passcodeError != null,
                          onChanged: (v) {
                            _updatePasscodeCriteria(v);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              ref.watch(pinVisibilityProvider)
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: AppLayout.scaleWidth(context, 20),
                            ),
                            onPressed: () {
                              ref.read(pinVisibilityProvider.notifier).state =
                                  !ref
                                      .read(pinVisibilityProvider.notifier)
                                      .state;
                            },
                          ),
                        ),
                        // ERROR BELOW FIELD
                        _buildFieldError(_passcodeError),

                        SizedBox(height: AppLayout.scaleHeight(context, 10)),
                        _buildPasscodeCriteria(context),

                        SizedBox(height: AppLayout.scaleHeight(context, 14)),

                        //  Confirm Passcode
                        _buildLabel(context, 'Confirm Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildPlainField(
                          context,
                          controller: confirmPasswordController,
                          obscureText: !ref.watch(confirmPinVisibilityProvider),
                          enabled: !isLoading && isOnline,
                          hasError: _confirmPasscodeError != null,
                          onChanged: (_) {
                            if (_confirmPasscodeError != null) {
                              setState(() => _confirmPasscodeError = null);
                            }
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              ref.watch(confirmPinVisibilityProvider)
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: AppLayout.scaleWidth(context, 20),
                            ),
                            onPressed: () {
                              ref
                                      .read(confirmPinVisibilityProvider.notifier)
                                      .state =
                                  !ref
                                      .read(
                                          confirmPinVisibilityProvider.notifier)
                                      .state;
                            },
                          ),
                        ),
                        // ERROR BELOW FIELD
                        _buildFieldError(_confirmPasscodeError),

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
  // PASSCODE CRITERIA CHECKLIST
  // ---------------------------------------------------------------------------

  Widget _buildPasscodeCriteria(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCriteriaRow(context, '8�12 characters', _hasMinLength),
        _buildCriteriaRow(
            context, 'At least one uppercase letter', _hasUppercase),
        _buildCriteriaRow(
            context, 'At least one lowercase letter', _hasLowercase),
        _buildCriteriaRow(context, 'At least one number', _hasNumber),
        _buildCriteriaRow(context, 'At least one special character (!@#\$%^&*)',
            _hasSpecialChar),
      ],
    );
  }

  Widget _buildCriteriaRow(BuildContext context, String label, bool isMet) {
    final Color activeColor = AppColors.primaryTeal;
    final Color inactiveColor = Colors.grey[400]!;

    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 5)),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: (_passcodeFieldTouched && isMet)
                ? Icon(Icons.check_circle,
                    key: const ValueKey(true),
                    size: AppLayout.scaleWidth(context, 15),
                    color: activeColor)
                : Icon(Icons.radio_button_unchecked,
                    key: const ValueKey(false),
                    size: AppLayout.scaleWidth(context, 15),
                    color: inactiveColor),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 6)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: (_passcodeFieldTouched && isMet)
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
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
