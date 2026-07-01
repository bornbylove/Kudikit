import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

import 'package:kudipay/presentation/agent/agent_registration_widgets.dart';

// =============================================================================
// Step 4: Bank Account
// Auto-resolves the account name as soon as 10 digits are entered.
// =============================================================================

class Step4BankAccountScreen extends ConsumerStatefulWidget {
  const Step4BankAccountScreen({super.key});

  @override
  ConsumerState<Step4BankAccountScreen> createState() => _Step4State();
}

class _Step4State extends ConsumerState<Step4BankAccountScreen> {
  late final TextEditingController _accountCtrl;

  @override
  void initState() {
    super.initState();
    final app = ref.read(agentRegistrationProvider).application;
    _accountCtrl = TextEditingController(text: app.accountNumber);
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentRegistrationProvider);
    final notifier = ref.read(agentRegistrationProvider.notifier);
    final app = state.application;

    final radius = AppLayout.scaleWidth(context, 10);
    final hPad = AppLayout.scaleWidth(context, 14);
    final vPad = AppLayout.scaleHeight(context, 13);

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
                // ── Header ───────────────────────────────────────────────────
                Text(
                  'Bank Account',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  'Add the bank account where your earnings will be paid.',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: AppColors.textGrey,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // ── Bank + account fields ─────────────────────────────────────
                KudiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank name — read-only, pre-filled
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: vPad),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundScreen,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Text(
                          'Kudikit',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 10)),

                      // Account number input
                      TextField(
                        controller: _accountCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: notifier.updateAccountNumber,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit Account No. or Phone No.',
                          hintStyle: TextStyle(
                            color: AppColors.textLight,
                            fontSize: AppLayout.fontSize(context, 13),
                          ),
                          counterText: '', // suppress "10/10" counter
                          suffixIcon: _buildSuffix(context, state, app),
                          filled: true,
                          fillColor: AppColors.backgroundScreen,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: hPad, vertical: vPad),
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
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),

                      // Resolved account name badge
                      if (app.accountName.isNotEmpty) ...[
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 12),
                            vertical: AppLayout.scaleHeight(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGreen,
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 8)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: AppColors.primaryTeal,
                                  size: AppLayout.scaleWidth(context, 14)),
                              SizedBox(width: AppLayout.scaleWidth(context, 6)),
                              Text(
                                app.accountName,
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 12),
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Lookup error
                      if (state.accountLookupError != null) ...[
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        Text(
                          state.accountLookupError!,
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 100)),
              ],
            ),
          ),
        ),
        KudiPrimaryButton(
          label: 'Continue',
          onPressed: app.isStep4Valid ? () => notifier.nextStep() : null,
        ),
      ],
    );
  }

  /// Shows a spinner while looking up, a green checkmark when resolved.
  Widget? _buildSuffix(
    BuildContext context,
    AgentRegistrationState state,
    app,
  ) {
    if (state.isLookingUpAccount) {
      return Padding(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
        child: SizedBox(
          width: AppLayout.scaleWidth(context, 18),
          height: AppLayout.scaleWidth(context, 18),
          child: const CircularProgressIndicator(
            strokeWidth: 1,
            color: AppColors.primaryTeal,
            strokeCap: StrokeCap.round,
          ),
        ),
      );
    }
    if (app.accountName.isNotEmpty) {
      return Icon(
        Icons.check_circle_outline,
        color: AppColors.primaryTeal,
        size: AppLayout.scaleWidth(context, 20),
      );
    }
    return null;
  }
}
