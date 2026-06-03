import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'package:kudipay/model/agent/agent_application_model.dart';
import 'package:kudipay/presentation/agent/bank_account_step4.dart';
import 'package:kudipay/presentation/agent/business_location_step2.dart';
import 'package:kudipay/presentation/agent/business_setup_step3.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

import 'review_application_screen.dart';

// =============================================================================
// AgentRegistrationFlow
// Hosts all 4 steps inside a single Scaffold.
// The AppBar (title + progress badge) is owned here — each step widget only
// renders its scrollable content + bottom button.
// =============================================================================

class AgentRegistrationFlow extends ConsumerWidget {
  const AgentRegistrationFlow({super.key});

  static const _titles = [
    'Business Information',
    'Business Location',
    'Business Setup',
    'Bank Account',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentRegistrationProvider);
    final notifier = ref.read(agentRegistrationProvider.notifier);

    // Step 4 completed ? push review screen
    if (state.currentStep >= 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          PageTransition(const ReviewApplicationScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return PopScope(
    onPopInvokedWithResult: (didPop, _) {
        // Android back: go to previous step instead of leaving the flow
        if (didPop && state.currentStep > 0) {
          notifier.goToStep(state.currentStep - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundScreen,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundScreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textDark,
              size: 20,
            ),
            onPressed: () {
              if (state.currentStep > 0) {
                notifier.goToStep(state.currentStep - 1);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _titles[state.currentStep],
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
              child: KudiCircularProgress(progress: state.progressPercent),
            ),
          ],
        ),
        // Each step widget owns its own SingleChildScrollView + bottom button
        body: _buildStep(state.currentStep),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const Step1BusinessInfoScreen();
      case 1:
        return const Step2BusinessLocationScreen();
      case 2:
        return const Step3BusinessSetupScreen();
      case 3:
        return const Step4BankAccountScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Step 1: Business Information
// =============================================================================

class Step1BusinessInfoScreen extends ConsumerStatefulWidget {
  const Step1BusinessInfoScreen({super.key});

  @override
  ConsumerState<Step1BusinessInfoScreen> createState() => _Step1State();
}

class _Step1State extends ConsumerState<Step1BusinessInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final app = ref.read(agentRegistrationProvider).application;
    _nameCtrl = TextEditingController(text: app.businessName);
    _descCtrl = TextEditingController(text: app.businessDescription);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentRegistrationProvider);
    final notifier = ref.read(agentRegistrationProvider.notifier);
    final app = state.application;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KudiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Business Name -------------------------------------
                      KudiFieldLabel('Business Name'),
                      SizedBox(height: AppLayout.scaleHeight(context, 6)),
                      KudiInputField(
                        hint: "E.g Adewole's supermarket",
                        controller: _nameCtrl,
                        onChanged: notifier.updateBusinessName,
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 4)),
                      KudiHintText(
                          'This is how customers will identify your location'),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),

                      // -- Business Type -------------------------------------
                      KudiFieldLabel('Business Type'),
                      SizedBox(height: AppLayout.scaleHeight(context, 6)),
                      _BusinessTypeDropdown(
                        selected: app.businessType,
                        onChanged: notifier.updateBusinessType,
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 4)),
                      KudiHintText('Help customers find the right agent'),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),

                      // -- Business Description ------------------------------
                      KudiFieldLabel('Business Description'),
                      SizedBox(height: AppLayout.scaleHeight(context, 6)),
                      KudiInputField(
                        hint: 'Tell customer about your business',
                        controller: _descCtrl,
                        onChanged: notifier.updateBusinessDescription,
                        maxLines: 4,
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 4)),
                      KudiHintText(
                          'Optional: Add any special services or landmarks nearby'),
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                KudiInfoBanner(
                    'A clear business name and description helps customers find and trust you'),
                SizedBox(height: AppLayout.scaleHeight(context, 100)),
              ],
            ),
          ),
        ),
        KudiPrimaryButton(
          label: 'Continue',
          onPressed: app.isStep1Valid ? () => notifier.nextStep() : null,
        ),
      ],
    );
  }
}

// =============================================================================
// Shared widgets — named with Kudi prefix so they can be exported and reused
// across Step 2, 3, 4 screens without private-class conflicts.
// =============================================================================

/// White card with shadow — used in every step.
class KudiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const KudiCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 12),
            offset: Offset(0, AppLayout.scaleHeight(context, 4)),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bold field label — "Business Name", "Cash Float", etc.
class KudiFieldLabel extends StatelessWidget {
  final String text;
  const KudiFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'PolySans',
          fontSize: AppLayout.fontSize(context, 13),
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}

/// Small grey helper text below fields.
class KudiHintText extends StatelessWidget {
  final String text;
  const KudiHintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 11),
          color: AppColors.textLight,
        ),
      );
}

/// Standard text input field — filled grey background, teal focus border.
class KudiInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? prefixText;
  final bool readOnly;

  const KudiInputField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.scaleWidth(context, 14);
    final vPad = AppLayout.scaleHeight(context, 13);
    final radius = AppLayout.scaleWidth(context, 10);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: AppColors.textLight,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundScreen,
        contentPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}

/// Teal tinted info banner with an info icon.
class KudiInfoBanner extends StatelessWidget {
  final String message;
  const KudiInfoBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 16)),
          SizedBox(width: AppLayout.scaleWidth(context, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width primary CTA button pinned to the bottom of each step.
class KudiPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const KudiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 28),
      ),
      color: AppColors.backgroundScreen,
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? AppColors.primaryTeal
                : AppColors.primaryTeal.withValues(alpha: 0.4),
            disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: AppLayout.scaleWidth(context, 22),
                  height: AppLayout.scaleWidth(context, 22),
                  child: const CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 1,
                    strokeCap: StrokeCap.round,
                  ),
                )
              : Text(label, style: AppTextStyles.responsiveButtonText(context)),
        ),
      ),
    );
  }
}

/// Circular arc progress badge — shown in the AppBar across all steps.
class KudiCircularProgress extends StatelessWidget {
  final double progress; // 0.0 – 1.0

  const KudiCircularProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.scaleWidth(context, 40);
    final percent = (progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    const sw = 3.0;

    // Track ring
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    // Filled arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.primaryTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// =============================================================================
// Business Type Dropdown — private to this file (only used in Step 1)
// =============================================================================

class _BusinessTypeDropdown extends StatelessWidget {
  final BusinessType? selected;
  final ValueChanged<BusinessType> onChanged;

  const _BusinessTypeDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final radius = AppLayout.scaleWidth(context, 10);
    final hPad = AppLayout.scaleWidth(context, 14);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundScreen,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BusinessType>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Select business type',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: AppLayout.fontSize(context, 14),
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGrey,
            size: AppLayout.scaleWidth(context, 20),
          ),
          items: BusinessType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: AppColors.textDark,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}