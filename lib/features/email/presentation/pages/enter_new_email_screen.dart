import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:kudipay/provider/email/email_provider.dart';

class EnterNewEmailScreen extends ConsumerStatefulWidget {
  const EnterNewEmailScreen({super.key});

  @override
  ConsumerState<EnterNewEmailScreen> createState() =>
      _EnterNewEmailScreenState();
}

class _EnterNewEmailScreenState extends ConsumerState<EnterNewEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final emailChangeState = ref.watch(emailChangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            ref.read(emailChangeProvider.notifier).goBack();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Title
                Text(
                  'Change Email',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 24),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),

                // Subtitle
                Text(
                  'Kindly fill in your new email.',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 32)),

                // Email label
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),

                // Email Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'example@gmail.com',
                      hintStyle: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 16),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!_isValidEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),

                const Spacer(),

                // Change Button
                SizedBox(
                  width: double.infinity,
                  height: AppLayout.scaleHeight(context, 52),
                  child: ElevatedButton(
                    onPressed: emailChangeState.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await ref
                                  .read(emailChangeProvider.notifier)
                                  .changeEmail(_emailController.text.trim());

                              if (success && context.mounted) {
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Email changed successfully!'),
                                    backgroundColor: Color(0xFF069494),
                                  ),
                                );

                                // Pop all screens and return to profile
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      emailChangeState.errorMessage ??
                                          'Failed to change email',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: emailChangeState.isLoading
                        ? const AppLoadingIndicator.button()
                        : Text(
                            'Change',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
