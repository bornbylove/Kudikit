import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/kyc/kyc_provider.dart';

import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/Identity/upload_ID.dart';

class AddressVerificationScreen extends ConsumerWidget {
  const AddressVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressData = ref.watch(addressProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final availableLgas = ref.watch(availableLgasProvider);

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
              SizedBox(height: AppLayout.scaleHeight(context, 40)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: addressData.isComplete
                      ? () async {
                          // ✅ Update auth state
                          await ref.read(authProvider.notifier).updateKycStatus(
                                isAddressVerified: true,
                              );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadIdCardScreen(),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
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
                      color:
                          addressData.isComplete ? Colors.white : Colors.grey,
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
