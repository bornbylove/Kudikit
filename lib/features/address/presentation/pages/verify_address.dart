import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/address/domain/entities/nigeria_state.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

// provider.dart re-exports the KYC controllers (addressProvider,
// utilityBillProvider, submitAddressUseCaseProvider).
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/kyc/presentation/controllers/kyc_controllers.dart';
import 'package:kudipay/features/identity/presentation/pages/upload_id.dart';

class AddressVerificationScreen extends ConsumerWidget {
  const AddressVerificationScreen({super.key});

  Future<void> _pickUtilityBill(WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      final path = result?.files.single.path;
      if (path != null) {
        ref.read(utilityBillProvider.notifier).state = File(path);
      }
    } catch (e) {
      debugPrint('Error picking utility bill: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressData = ref.watch(addressProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final availableLgas = ref.watch(availableLgasProvider);
    final utilityBill = ref.watch(utilityBillProvider);
    // verify-address requires utilityBillImageBase64, so the form is not
    // submittable on the text fields alone.
    final canSubmit = addressData.isComplete && utilityBill != null;

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
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
                'Verify Your Address',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              Text(
                'Required for Mega Tribe. An agent will visit to confirm.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              _label(context, 'State'),
              _dropdownContainer(
                context,
                DropdownButtonFormField<String>(
                  initialValue: addressData.state,
                  hint: const Text('Select State'),
                  isExpanded: true,
                  decoration: _inputDecoration(context),
                  items: nigeriaLocations.map((location) {
                    return DropdownMenuItem(
                      value: location.state,
                      child: Text(location.state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(selectedStateProvider.notifier).state = value;
                      ref.read(addressProvider.notifier).updateState(value);
                    }
                  },
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              _label(context, 'City'),
              _textField(
                context,
                initialValue: addressData.city,
                hint: 'Enter City',
                onChanged: ref.read(addressProvider.notifier).updateCity,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              _label(context, 'LGA'),
              _dropdownContainer(
                context,
                DropdownButtonFormField<String>(
                  initialValue: addressData.lga,
                  hint: Text(selectedState == null
                      ? 'Select State First'
                      : 'Select LGA'),
                  isExpanded: true,
                  decoration: _inputDecoration(context),
                  items: availableLgas.map((lga) {
                    return DropdownMenuItem(value: lga, child: Text(lga));
                  }).toList(),
                  onChanged: selectedState == null
                      ? null
                      : (value) {
                          if (value != null) {
                            ref.read(addressProvider.notifier).updateLga(value);
                          }
                        },
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Landmark Input
              const Text(
                'Landmark',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  initialValue: addressData.landmark,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter Landmark',
                  ),
                  onChanged: (value) {
                    ref.read(addressProvider.notifier).updateLandmark(value);
                  },
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Street Name Input
              const Text(
                'Street Name',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  initialValue: addressData.streetName,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter Street Name',
                  ),
                  onChanged: (value) {
                    ref.read(addressProvider.notifier).updateStreetName(value);
                  },
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // House Number Input
              const Text(
                'House Number',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  initialValue: addressData.houseNumber,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter House Number',
                  ),
                  onChanged: (value) {
                    ref.read(addressProvider.notifier).updateHouseNumber(value);
                  },
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // -- Proof of address ------------------------------------------
              Text(
                'Utility Bill',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 8)),
              GestureDetector(
                onTap: () => _pickUtilityBill(ref),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
                    border: Border.all(
                      color: utilityBill != null
                          ? AppColors.primaryTeal
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        utilityBill != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color: utilityBill != null
                            ? AppColors.primaryTeal
                            : Colors.grey,
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: Text(
                          utilityBill != null
                              ? utilityBill.path
                                  .split(Platform.pathSeparator)
                                  .last
                              : 'Upload a recent utility bill',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: utilityBill != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 40)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          try {
                            // Actually submit — this previously only set a
                            // local flag and sent nothing to the server.
                            final kyc = await ref
                                .read(submitAddressUseCaseProvider)
                                .call(
                                  AddressEntity(
                                    state: addressData.state,
                                    city: addressData.city,
                                    lga: addressData.lga,
                                    landmark: addressData.landmark,
                                    streetName: addressData.streetName,
                                    houseNumber: addressData.houseNumber,
                                  ),
                                  utilityBill: utilityBill,
                                );

                            // Address verification is agent-visited, so the
                            // server usually returns PENDING_AGENT_VISIT
                            // rather than VERIFIED. Mirror its verdict.
                            await ref
                                .read(authProvider.notifier)
                                .updateKycStatus(
                                  isAddressVerified: kyc.addressVerified,
                                );

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UploadIdCardScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: canSubmit ? Colors.white : Colors.grey,
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

Widget _label(BuildContext context, String text) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text,
          style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w500)),
      SizedBox(height: AppLayout.scaleHeight(context, 5)),
    ],
  );
}

Widget _dropdownContainer(BuildContext context, Widget child) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
    ),
    child: child,
  );
}

Widget _textField(BuildContext context,
    {required String? initialValue,
    required String hint,
    required ValueChanged<String> onChanged}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
    ),
    child: TextFormField(
      initialValue: initialValue,
      decoration: _inputDecoration(context, hint: hint),
      onChanged: onChanged,
    ),
  );
}

InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
  return InputDecoration(
    hintText: hint,
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppLayout.scaleWidth(context, 16),
      vertical: AppLayout.scaleHeight(context, 12),
    ),
  );
}
