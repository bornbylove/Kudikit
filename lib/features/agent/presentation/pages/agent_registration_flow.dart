import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/page_transition.dart';
import 'package:kudipay/features/agent/domain/entities/agent_application_model.dart';
import 'package:kudipay/features/agent/presentation/pages/bank_account_step4.dart';
import 'package:kudipay/features/agent/presentation/pages/business_location_step2.dart';
import 'package:kudipay/features/agent/presentation/pages/business_setup_step3.dart';
import 'package:kudipay/features/agent/presentation/pages/agent_registration_widgets.dart';
import 'package:kudipay/features/agent/presentation/controllers/agent_registration_provider.dart';

import 'review_application_screen.dart';

// =============================================================================
// AgentRegistrationFlow
// Hosts all 4 steps inside a single Scaffold.
// The AppBar (title + progress badge) is owned here � each step widget only
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
              padding:
                  EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
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
                      KudiFieldLabel('Business Type'),
                      SizedBox(height: AppLayout.scaleHeight(context, 6)),
                      _BusinessTypeDropdown(
                        selected: app.businessType,
                        onChanged: notifier.updateBusinessType,
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 4)),
                      KudiHintText('Help customers find the right agent'),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),
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
// Business Type Dropdown � private to this file (only used in Step 1)
// =============================================================================

class _BusinessTypeDropdown extends StatelessWidget {
  final BusinessType? selected;
  final ValueChanged<BusinessType> onChanged;

  const _BusinessTypeDropdown(
      {required this.selected, required this.onChanged});

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
