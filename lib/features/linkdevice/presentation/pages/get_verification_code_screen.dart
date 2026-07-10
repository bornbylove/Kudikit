import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/sign_in_verify_email_screen.dart';
import 'package:kudipay/provider/provider.dart';

class GetVerificationCodeScreen extends ConsumerStatefulWidget {
  const GetVerificationCodeScreen({super.key});

  @override
  ConsumerState<GetVerificationCodeScreen> createState() =>
      _GetVerificationCodeScreenState();
}

class _GetVerificationCodeScreenState
    extends ConsumerState<GetVerificationCodeScreen> {
  VerificationMethod _selectedMethod = VerificationMethod.email;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceLinkingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      // FIX: Wrap in Stack so the loading overlay can sit on top of everything.
      // FIX: Column → SafeArea+Column so button sits at bottom without overlapping.
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody(context, state)),
                _buildButton(context, state),
              ],
            ),
          ),
          // FIX: Loading overlay is now correctly inside the Stack.
          if (state.isSendingCode)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeviceLinkingState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
          Text(
            'Get verification code',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 24),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            'Choose how you\'d like to receive your code',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: Colors.black54,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),
          _buildMethodOption(
            context,
            method: VerificationMethod.email,
            icon: Icons.email_outlined,
            title: 'Send code to my registered email',
            subtitle: state.data?.maskedEmail ?? 'u***8@gmail.com',
            isSelected: _selectedMethod == VerificationMethod.email,
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildMethodOption(
            context,
            method: VerificationMethod.oldDevice,
            icon: Icons.phone_iphone,
            title: 'Show code on my old phone',
            subtitle: state.data?.oldDeviceName ?? 'iPhone 14 Pro',
            isSelected: _selectedMethod == VerificationMethod.oldDevice,
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    BuildContext context, {
    required VerificationMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
        ref
            .read(deviceLinkingProvider.notifier)
            .selectVerificationMethod(method);
      },
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 48),
              height: AppLayout.scaleWidth(context, 43),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal.withValues(alpha: 0.35)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryTeal : Colors.black54,
                size: AppLayout.scaleWidth(context, 22),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              color: isSelected ? AppColors.primaryTeal : Colors.black26,
              size: AppLayout.scaleWidth(context, 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, DeviceLinkingState state) {
    // FIX: was Positioned inside a Column — Positioned only works inside Stack.
    // Replaced with plain Padding so it sticks to the bottom of the Column.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 24),
        AppLayout.scaleHeight(context, 40),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          onPressed: state.isSendingCode
              ? null
              : () async {
                  await ref
                      .read(deviceLinkingProvider.notifier)
                      .sendVerificationCode();

                  // FIX: read fresh state after await instead of using
                  // stale captured state.
                  final fresh = ref.read(deviceLinkingProvider);
                  if (context.mounted && fresh.data?.isCodeSent == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInVerifyEmailScreen(
                          maskedEmail: '',
                        ),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Text(
            'Continue',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
