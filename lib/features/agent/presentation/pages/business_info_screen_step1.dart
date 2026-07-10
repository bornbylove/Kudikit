import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/shared_widget.dart';
import 'package:kudipay/model/agent/agent_application_model.dart';
import 'package:kudipay/provider/agent/agent_registration_provider.dart';

class Step1BusinessInfoScreen extends ConsumerStatefulWidget {
  const Step1BusinessInfoScreen({super.key});

  @override
  ConsumerState<Step1BusinessInfoScreen> createState() =>
      _Step1BusinessInfoScreenState();
}

class _Step1BusinessInfoScreenState
    extends ConsumerState<Step1BusinessInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final app = ref.read(agentRegistrationProvider).application;
    _nameController = TextEditingController(text: app.businessName);
    _descController = TextEditingController(text: app.businessDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name
                      const _FieldLabel('Business Name'),
                      const SizedBox(height: 6),
                      LabelledField(
                        hint: 'E.g Adewole\'s supermarket',
                        controller: _nameController,
                        onChanged: notifier.updateBusinessName,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This is how customers will identify your location',
                        style: TextStyle(fontSize: 11, color: kTextLight),
                      ),
                      const SizedBox(height: 16),

                      // Business Type
                      const _FieldLabel('Business Type'),
                      const SizedBox(height: 6),
                      _BusinessTypeDropdown(
                        selected: app.businessType,
                        onChanged: notifier.updateBusinessType,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Help customers find the right agent',
                        style: TextStyle(fontSize: 11, color: kTextLight),
                      ),
                      const SizedBox(height: 16),

                      // Business Description
                      const _FieldLabel('Business Description'),
                      const SizedBox(height: 6),
                      LabelledField(
                        hint: 'Tell customer about your business',
                        controller: _descController,
                        onChanged: notifier.updateBusinessDescription,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Optional: Add any special services or landmarks nearby',
                        style: TextStyle(fontSize: 11, color: kTextLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const InfoBanner(
                  message:
                      'A clear business name and description helps customers find and trust you',
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        PrimaryButton(
          label: 'Continue',
          onPressed: app.isStep1Valid ? () => notifier.nextStep() : null,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    );
  }
}

class _BusinessTypeDropdown extends StatelessWidget {
  final BusinessType? selected;
  final ValueChanged<BusinessType> onChanged;

  const _BusinessTypeDropdown({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BusinessType>(
          value: selected,
          isExpanded: true,
          hint: const Text(
            'Select business type',
            style: TextStyle(color: kTextLight, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextMid),
          items: BusinessType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.label,
                style: const TextStyle(fontSize: 14, color: kTextDark),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
