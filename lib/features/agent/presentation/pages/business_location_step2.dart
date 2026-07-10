import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/agent/presentation/controllers/agent_registration_provider.dart';
import 'package:kudipay/features/agent/presentation/pages/agent_registration_widgets.dart';

class Step2BusinessLocationScreen extends ConsumerStatefulWidget {
  const Step2BusinessLocationScreen({super.key});

  @override
  ConsumerState<Step2BusinessLocationScreen> createState() => _Step2State();
}

class _Step2State extends ConsumerState<Step2BusinessLocationScreen> {
  late final TextEditingController _addressCtrl;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    final app = ref.read(agentRegistrationProvider).application;
    _addressCtrl = TextEditingController(text: app.businessAddress);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _localPhotoPath = image.path);
      // Production: upload to Firebase Storage, store the download URL
      ref
          .read(agentRegistrationProvider.notifier)
          .updateStorefrontPhoto(image.path);
    }
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
                Text(
                  'Business Location',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // ── Business address search ────────────────────────────────
                KudiFieldLabel('Business Address'),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundScreen,
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 10)),
                  ),
                  child: TextField(
                    controller: _addressCtrl,
                    onChanged: notifier.updateBusinessAddress,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by address or landmark',
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: AppLayout.fontSize(context, 14),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textGrey,
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14)),
                    ),
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // ── Storefront photo ──────────────────────────────────────
                KudiFieldLabel('Storefront Photo'),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: double.infinity,
                    height: AppLayout.scaleHeight(context, 160),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundScreen,
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 12)),
                    ),
                    child: _localPhotoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 12)),
                            child: Image.asset(
                              _localPhotoPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _photoPlaceholder(context),
                            ),
                          )
                        : _photoPlaceholder(context),
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 100)),
              ],
            ),
          ),
        ),
        KudiPrimaryButton(
          label: 'Continue',
          onPressed: app.isStep2Valid ? () => notifier.nextStep() : null,
        ),
      ],
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: AppLayout.scaleWidth(context, 32),
          color: AppColors.textLight,
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 10)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 8),
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
          ),
          child: Text(
            'Upload Photo',
            style: TextStyle(
              color: AppColors.primaryTeal,
              fontSize: AppLayout.fontSize(context, 13),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
