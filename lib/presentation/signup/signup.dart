import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/phone_number.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/services/api_services.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/signup/signup_verify.dart';
import 'package:flutter_riverpod/legacy.dart';


class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

 // final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // FORM KEY — still used to trigger _validate() on submit
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // PER-FIELD ERROR STRINGS
  
 // String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passcodeError;
  String? _confirmPasscodeError;

  // ---------------------------------------------------------------------------
  // LOADING STATE — local now that this screen only fires send-otp (not the
  // full register()), so it no longer reflects global authProvider state.
  // ---------------------------------------------------------------------------

  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // LOCAL TERMS ACCEPTANCE STATE
  // ---------------------------------------------------------------------------

  final _termsAcceptedProvider = StateProvider<bool>((ref) => false);

  // ---------------------------------------------------------------------------
  // PASSCODE CRITERIA STATE
  // ---------------------------------------------------------------------------
  // PRD Passcode Security Rules (Registration Screen §8, confirmed
  // 2026-08-10): 6-8 numeric digits, not sequential/repetitive/a common
  // PIN/a date pattern, not derived from the phone number. NOT the 8-12
  // char alphanumeric+special shape this screen briefly enforced.

  bool _hasValidLength = false;
  bool _isDigitsOnly = false;
  bool _isNotSimplePattern = false;
  bool _passcodeFieldTouched = false;
  ProviderSubscription<AsyncValue<bool>>? _connectivitySubscription;

  // ---------------------------------------------------------------------------
  // SUBMIT READINESS
  // ---------------------------------------------------------------------------


  bool get _fieldsReady =>
      emailController.text.trim().isNotEmpty &&
      numberController.text.trim().length == 10 &&
      _hasValidLength &&
      _isDigitsOnly &&
      _isNotSimplePattern &&
      confirmPasswordController.text == passwordController.text &&
      confirmPasswordController.text.isNotEmpty;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    
  //  fullNameController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    numberController.addListener(_onFieldChanged);
    confirmPasswordController.addListener(_onFieldChanged);
    _setupConnectivityListener();
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
  //  fullNameController.removeListener(_onFieldChanged);
    emailController.removeListener(_onFieldChanged);
    numberController.removeListener(_onFieldChanged);
    confirmPasswordController.removeListener(_onFieldChanged);
  //  fullNameController.dispose();
    emailController.dispose();
    numberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _connectivitySubscription?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CONNECTIVITY LISTENER
  // ---------------------------------------------------------------------------

  void _setupConnectivityListener() {
    _connectivitySubscription = ref.listenManual(connectivityProvider, (previous, next) {
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
      _isDigitsOnly = value.isNotEmpty && RegExp(r'^\d+$').hasMatch(value);
      _hasValidLength = value.length >= 6 && value.length <= 8;
      _isNotSimplePattern = _isDigitsOnly &&
          !_isSequentialPasscode(value) &&
          !_isRepetitivePasscode(value);
      // Clear the passcode error as the user types
      if (_passcodeError != null) _passcodeError = null;
    });
  }

  bool _isSequentialPasscode(String value) {
    var ascending = true;
    var descending = true;
    for (var i = 1; i < value.length; i++) {
      final prev = value.codeUnitAt(i - 1) - 48;
      final curr = value.codeUnitAt(i) - 48;
      if (curr != prev + 1) ascending = false;
      if (curr != prev - 1) descending = false;
    }
    return value.length > 1 && (ascending || descending);
  }

  bool _isRepetitivePasscode(String value) {
    if (value.isEmpty) return false;
    final first = value[0];
    return value.split('').every((c) => c == first);
  }

  // ---------------------------------------------------------------------------
  // FIELD-LEVEL VALIDATION
  // ---------------------------------------------------------------------------


  bool _validateFields() {
    bool valid = true;
    setState(() {
      // Full name
      // final fullName = fullNameController.text.trim();
      // if (fullName.isEmpty) {
      //   _fullNameError = 'Please enter your full name';
      //   valid = false;
      // } else if (!fullName.contains(' ')) {
      //   _fullNameError = 'Please enter your first and last name';
      //   valid = false;
      // } else {
      //   _fullNameError = null;
      // }

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
      // Same rule as the server's ^\+234[7-9][0-1]\d{8}$ — a bare "10 digits"
      // check let numbers like 6015697383 through to a server 400.
      final phone = numberController.text.trim();
      final phoneError = nigerianPhoneError(phone);
      if (phoneError != null) {
        _phoneError = phoneError;
        valid = false;
      } else {
        _phoneError = null;
      }

      // Passcode — mirrors the server's PasscodeValidator exactly (6-8
      // digits, numeric only, not sequential/repetitive/common, doesn't
      // contain the phone number) via StorageService's shared validator.
      final passcode = passwordController.text;
      if (passcode.isEmpty) {
        _passcodeError = 'Please enter a passcode';
        valid = false;
      } else {
        final fullPhone = normalizeNigerianPhone(numberController.text) ??
            '+234${numberController.text.trim()}';
        final error = StorageService.instance
            .passcodeValidationError(passcode, phoneNumber: fullPhone);
        if (error != null) {
          _passcodeError = error;
          valid = false;
        } else {
          _passcodeError = null;
        }
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
          content: Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: AppColors.avatarRed,
        ),
      );
      return;
    }

   // final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    // Validated above, so this is the E.164 form the server stores.
    final phoneNumber = normalizeNigerianPhone(numberController.text) ??
        '+234${numberController.text.trim()}';
    final password = passwordController.text.trim();

    // Hold the collected data — the actual /auth/register call fires later,
    // from KnowYouBetterForm, after OTP verification and referral collection.
    ref.read(registrationFlowProvider.notifier).setBasicInfo(
          phoneNumber: phoneNumber,
          email: email,
          passcode: password
   //       fullName: fullName,
        );

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).sendOtp(
            phoneNumber: phoneNumber,
            email: email,
            purpose: OtpPurpose.registration,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerifySignup(
            email: email,
            phoneNumber: phoneNumber,
          ),
        ),
      );
    } on NoInternetException {
      if (!mounted) return;
      ConnectivitySnackBar.showNoInternet(context);
    } on KudiNetworkException {
      if (!mounted) return;
      ConnectivitySnackBar.showNoInternet(context);
    } on KudiTimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.avatarOrange,
        ),
      );
    } on KudiApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.avatarRed,
        ),
      );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityStateProvider);
    final isLoading = _isLoading;
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
                            color: AppColors.textDark
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 25)),

                        // ── Full Name ──────────────────────────────────────
                        // _buildLabel(context, 'Full Name'),
                        // SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        // _buildPlainField(
                        //   context,
                        //   controller: fullNameController,
                        //   keyboardType: TextInputType.name,
                        //   enabled: !isLoading && isOnline,
                        //   hasError: _fullNameError != null,
                        //   onChanged: (_) {
                        //     if (_fullNameError != null) {
                        //       setState(() => _fullNameError = null);
                        //     }
                        //   },
                        // ),
                        // // ERROR BELOW FIELD
                        // _buildFieldError(_fullNameError),
                        //
                        // SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // ── Email ──────────────────────────────────────────
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

                        // ── Phone Number ───────────────────────────────────
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

                        // ── Passcode ───────────────────────────────────────
                        _buildLabel(context, 'Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildPlainField(
                          context,
                          controller: passwordController,
                          obscureText: !ref.watch(pinVisibilityProvider),
                          enabled: !isLoading && isOnline,
                          hasError: _passcodeError != null,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
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
                                  !ref.read(pinVisibilityProvider.notifier).state;
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
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
                              ref.read(confirmPinVisibilityProvider.notifier).state =
                                  !ref.read(confirmPinVisibilityProvider.notifier).state;
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
                        _buildSubmitButton(context, isLoading, isOnline, canSubmit),

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
      backgroundColor: const Color(0xFFF5F5F0),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
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
              'No internet — Sign up requires a connection',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(connectivityStateProvider.notifier).refresh(),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(BuildContext context, bool isLoading, bool isOnline) {
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
                    ref.read(_termsAcceptedProvider.notifier).state = value ?? false;
                  },
            activeColor: const Color(0xFF069494),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 4)),
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
                    color: Color(0xFF069494),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF069494),
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
          color: const Color(0xFF069494),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(
                        email: emailController.text.trim(),
                      ),
                    ),
                  );
                },
          child: Text(
            'Log in',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: isOnline ? const Color(0xFF069494) : Colors.grey,
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
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance, size: 20, color: Color(0xFF2C2C2C)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Licensed by the ', style: TextStyle(color: Colors.black, fontSize: 12)),
          const Text('CBN', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Text('and insured by the', style: TextStyle(color: Colors.black, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Image.asset(
              'assets/images/ndicc.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance, size: 20, color: Color(0xFF2C2C2C)),
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
        _buildCriteriaRow(context, '6-8 digits', _hasValidLength),
        _buildCriteriaRow(context, 'Numbers only', _isDigitsOnly),
        _buildCriteriaRow(context, 'Not sequential or repetitive (e.g. 123456 or 111111)',
            _isNotSimplePattern),
      ],
    );
  }

  Widget _buildCriteriaRow(BuildContext context, String label, bool isMet) {
    final Color activeColor = const Color(0xFF069494);
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
                color: (_passcodeFieldTouched && isMet) ? Colors.black87 : Colors.grey[600],
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
            color: Colors.black.withOpacity(0.03),
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