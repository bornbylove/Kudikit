import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/utils/image_base64_util.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/model/user/user_info.dart';

import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/Identity/confirm_info.dart';
import 'package:kudipay/services/geolocation_provider.dart';
import 'dart:io';

class AddressVerificationScreen extends ConsumerStatefulWidget {
  const AddressVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddressVerificationScreen> createState() =>
      _AddressVerificationScreenState();
}

class _AddressVerificationScreenState
    extends ConsumerState<AddressVerificationScreen> {
  File? _utilityBillFile;
  String? _utilityBillFileName;
  bool _isSubmitting = false;
  bool _isCapturingLocation = false;
  GeoCoordinates? _capturedCoordinates;

  // ── Slice 6 (MO-5): best-effort GPS capture through the provider
  //    abstraction. Coordinates are OPTIONAL — permission denial never blocks
  //    the address flow (manual entry remains the fallback).
  Future<void> _captureLocation() async {
    if (_isCapturingLocation) return;
    setState(() => _isCapturingLocation = true);
    final provider = ref.read(geolocationProvider);
    GeoCoordinates? coords;
    if (provider.isAvailable) {
      coords = await provider.getCurrentCoordinates();
    }
    if (!mounted) return;
    setState(() {
      _capturedCoordinates = coords;
      _isCapturingLocation = false;
    });
    if (coords == null) {
      _showMessage(
        'Location unavailable. You can still enter your address manually.',
      );
    }
  }

  Future<void> _pickUtilityBill() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _utilityBillFile = File(result.files.single.path!);
          _utilityBillFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking utility bill: $e');
    }
  }

  Future<void> _submitAddress() async {
    if (_isSubmitting) return;
    final address = ref.read(addressProvider);
    setState(() => _isSubmitting = true);

    try {
      final billBase64 = await ImageBase64Util.encodeToBase64(
          XFile(_utilityBillFile!.path));

      // Slice 5: real submission to POST /auth/kyc/verify-address. A 200
      // returns addressStatus = PENDING_AGENT_VISIT (NOT verified) — that
      // authoritative state is preserved through copyWithKyc. A 400 (e.g.
      // "Complete BVN or NIN verification...") surfaces the actual server
      // message. No bare local completion is set here.
      await ref.read(authProvider.notifier).verifyAddress(
            houseNumber: address.houseNumber!.trim(),
            street: address.streetName!.trim(),
            landmark: address.landmark?.trim(),
            area: address.area?.trim(),
            lga: address.lga!.trim(),
            city: address.city!.trim(),
            addressState: address.state!.trim(),
            utilityBillImageBase64: billBase64,
            latitude: _capturedCoordinates?.latitude,
            longitude: _capturedCoordinates?.longitude,
          );

      if (!mounted) return;

      // FIX: this used to push UploadIdCardScreen next, but by the time a
      // Mega user reaches address verification via KycFlowManager's
      // canonical order (Selfie → BVN/NIN → ID doc → Address), ID document
      // is already verified — re-prompting for it was a stale ordering bug.
      // Address is Mega's LAST requirement, so this goes straight to
      // ConfirmInfoScreen instead.
      final storageService = ref.read(storageServiceProvider);
      UserInfo? userInfo = await storageService.getUserInfo();
      if (userInfo == null) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          userInfo = UserInfo(
            firstName: currentUser.name?.split(' ').first ?? '',
            lastName: currentUser.name?.split(' ').last ?? '',
            bvn: currentUser.bvn ?? '',
            nin: currentUser.nin ?? '',
            dateOfBirth: DateTime(1990, 1, 1),
          );
        }
      }
      if (!mounted || userInfo == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfirmInfoScreen(userInfo: userInfo!)),
      );
    } on KudiApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF069494),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressData = ref.watch(addressProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final availableLgas = ref.watch(availableLgasProvider);
    final canSubmit = addressData.isComplete &&
        _utilityBillFile != null &&
        !_isSubmitting;

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
              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // ── Slice 6 GPS status (MO-5) ───────────────────────────────
              // Minimal, non-intrusive row: capture coordinates through the
              // provider abstraction. Manual entry below is unchanged.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 12),
                  vertical: AppLayout.scaleHeight(context, 10),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
                  border: Border.all(
                    color: _capturedCoordinates != null
                        ? const Color(0xFF069494)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _capturedCoordinates != null
                          ? Icons.location_on
                          : Icons.my_location,
                      size: AppLayout.scaleWidth(context, 18),
                      color: _capturedCoordinates != null
                          ? const Color(0xFF069494)
                          : Colors.grey[500],
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 10)),
                    Expanded(
                      child: Text(
                        _isCapturingLocation
                            ? 'Capturing your location...'
                            : _capturedCoordinates != null
                                ? 'Location captured (${_capturedCoordinates!.latitude.toStringAsFixed(4)}, '
                                    '${_capturedCoordinates!.longitude.toStringAsFixed(4)})'
                                : 'Add your current location to speed up verification',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (!_isCapturingLocation)
                      TextButton(
                        onPressed: _isSubmitting ? null : _captureLocation,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF069494),
                          minimumSize: Size.zero,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _capturedCoordinates != null
                              ? 'Change'
                              : 'Use my location',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 16)),
              _label(context, 'State'),
              _dropdownContainer(
                context,
                DropdownButtonFormField<String>(
                  value: addressData.state,
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
                  value: addressData.lga,
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

              // Area (optional) — natural slot after LGA, before landmark.
              const Text(
                'Area (optional)',
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
                  initialValue: addressData.area,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter Area',
                  ),
                  onChanged: (value) {
                    ref.read(addressProvider.notifier).updateArea(value);
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

              // Utility bill capture
              const Text(
                'Utility Bill',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSubmitting ? null : _pickUtilityBill,
                child: Container(
                  width: double.infinity,
                  height: AppLayout.scaleHeight(context, 140),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 12)),
                    border: Border.all(
                      color: _utilityBillFile != null
                          ? const Color(0xFF069494)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _utilityBillFile != null
                            ? Icons.check_circle
                            : Icons.cloud_upload_outlined,
                        size: AppLayout.scaleWidth(context, 36),
                        color: _utilityBillFile != null
                            ? const Color(0xFF069494)
                            : Colors.grey[400],
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Text(
                        _utilityBillFileName ?? 'Upload Utility Bill',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  onPressed: canSubmit ? _submitAddress : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  const Color(0xFF069494),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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