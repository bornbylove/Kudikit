// lib/features/auth/presentation/pages/forgot_passcode.dart
//
// Step 1 of 3 — collects the account identifier and requests a reset code.
//
//   forgot_passcode.dart        -> POST /auth/forgot-passcode/send-otp
//   forgot_passcode_verify.dart -> POST /auth/verify-otp (FORGOT_PASSCODE)
//   reset_passcode.dart         -> POST /auth/forgot-passcode/reset
//
// The identifier field accepts either an email or a Nigerian phone number;
// the repository routes it to the right request field.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/phone_number.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/auth/presentation/pages/forgot_passcode_verify.dart';

class ForgotPasscodeScreen extends ConsumerStatefulWidget {
  const ForgotPasscodeScreen({super.key});

  @override
  ConsumerState<ForgotPasscodeScreen> createState() =>
      _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends ConsumerState<ForgotPasscodeScreen> {
  final TextEditingController _identifierCtrl = TextEditingController();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Enter your email or phone number';
    if (value.contains('@')) {
      return value.contains('.') ? null : 'Enter a valid email address';
    }
    // Not an email — must then be a valid phone number.
    return looksLikeNigerianPhone(value)
        ? null
        : 'Enter a valid email or Nigerian phone number';
  }

  Future<void> _handleSend() async {
    final validationError = _validate(_identifierCtrl.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final otpReference = await ref
          .read(sendForgotPasscodeOtpUseCaseProvider)
          .call(identifier: _identifierCtrl.text.trim());

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasscodeVerifyScreen(
            otpReference: otpReference,
            identifier: _identifierCtrl.text.trim(),
          ),
        ),
      );
    } on KudiApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'Request timed out. Try again.');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Colors.black, size: AppLayout.scaleWidth(context, 18)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset your passcode',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'Enter the email or phone number on your account and we will '
                'send you a code.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              Text(
                'Email or Phone Number',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
                  border: Border.all(
                    color: _error != null
                        ? AppColors.avatarRed
                        : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _identifierCtrl,
                  enabled: !_isSending,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'you@example.com or 0701 569 7383',
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: AppColors.avatarRed,
                  ),
                ),
              ],
              SizedBox(height: AppLayout.scaleHeight(context, 40)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: AppLayout.scaleWidth(context, 20),
                          height: AppLayout.scaleWidth(context, 20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Send code',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
