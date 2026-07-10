import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/features/transaction/presentation/pages/transaction_success.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/api_services.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardTopUpState = ref.watch(cardTopUpProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context, isOnline),
      bottomNavigationBar: _buildVerifyButton(context, isOnline),
      body: Stack(
        children: [
          _buildBody(context, isOnline),
          if (cardTopUpState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF069494)),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isOnline) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Text(
            'Top-up with card or account',
            style: TextStyle(
              color: Colors.black,
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w600,
            ),
          ),
          // const SizedBox(width: 8),
          // Container(
          //   width: 8,
          //   height: 8,
          //   decoration: BoxDecoration(
          //     color: isOnline ? const Color(0xFF069494) : Colors.red,
          //     shape: BoxShape.circle,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isOnline) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Internet connection required to verify payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => ref
                          .read(connectivityStateProvider.notifier)
                          .refresh(),
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            _buildInstructionText(context),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
            _buildOtpField(context, isOnline),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    return Text(
      'Enter the code sent to the number connected to the bank card details you filled.',
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  Widget _buildOtpField(BuildContext context, bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Code',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          enabled: isOnline,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter OTP code';
            if (value.length < 4) return 'Please enter a valid OTP code';
            return null;
          },
          onChanged: (value) {
            if (value.length == 6 && isOnline) _handleVerify();
          },
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 16),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: isOnline ? Colors.black : Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: isOnline ? '' : 'Internet required',
            hintStyle: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.red[300],
            ),
            filled: true,
            fillColor: isOnline ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Color(0xFFf9f9f9), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
          ),
        ),
        if (!isOnline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text(
                  'Connect to internet to verify payment',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Moved to bottomNavigationBar — no longer Positioned inside a Stack.
  // Both BoxDecorations removed as requested.
  Widget _buildVerifyButton(BuildContext context, bool isOnline) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 8),
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 30),
        ),
        child: ElevatedButton(
          onPressed: isOnline
              ? _handleVerify
              : () => ConnectivitySnackBar.showNoInternet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isOnline ? const Color(0xFF069494) : Colors.grey[400],
            minimumSize: Size(
              double.infinity,
              AppLayout.scaleHeight(context, 50),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isOnline ? 'Verify Payment' : 'No Internet Connection',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (!isOnline)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.wifi_off, size: 18, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(cardTopUpProvider.notifier).verifyOtp(_otpController.text);

      final state = ref.read(cardTopUpProvider);

      if (mounted) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.receipt != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionReceiptScreen(),
            ),
          );
        }
      }
    } on NoInternetException {
      if (!mounted) return;
      ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
