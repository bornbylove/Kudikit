// lib/presentation/selfie/liveness_capture_screen.dart
//
// Dojah liveness verification screen. Camera/permission handling mirrors
// SelfieCaptureScreen in this same directory (front camera preferred via
// CameraController, image_picker as a fallback, permission_handler for
// graceful permission requests) — that screen's mock validation flow is
// left untouched; this is a new, separate screen wired to the real Dojah
// API through livenessProvider.
//
// Flow: Capturing (camera) -> ImageCaptured (preview, retake/continue) ->
// CheckingLiveness (uploading) -> Success/Failure dialog.
//
// NOTE for testing: Dojah's API (like this app's own auth-service — see the
// CORS advisory from the auth integration work) is very likely to reject or
// block browser-origin requests. This screen should be exercised on a native
// Android/iOS device or emulator, not Chrome.

import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:kudipay/model/identity/liveness_state.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
import 'package:kudipay/presentation/selfie/face_overlay.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/identity/liveness_provider.dart';

class LivenessCaptureScreen extends ConsumerStatefulWidget {
  const LivenessCaptureScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LivenessCaptureScreen> createState() =>
      _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState
    extends ConsumerState<LivenessCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _successDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(livenessProvider.notifier).startCapturing();
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) _showPermissionDeniedDialog();
      return;
    }

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera found on this device')),
          );
        }
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize the camera. Please try again.'),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to verify your identity. Please grant permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    XFile? image;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
    } else {
      try {
        image = await _cameraController!.takePicture();
      } catch (e) {
        debugPrint('Error capturing photo: $e');
        return;
      }
    }

    if (image == null || !mounted) return;
    setState(() => _capturedImage = image);
    ref.read(livenessProvider.notifier).imageCaptured(image.path);
  }

  void _retake() {
    setState(() => _capturedImage = null);
    ref.read(livenessProvider.notifier).retake();
  }

  Future<void> _submit() async {
    final image = _capturedImage;
    if (image == null) return;
    await ref.read(livenessProvider.notifier).submit(image);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livenessState = ref.watch(livenessProvider);

    ref.listen<LivenessState>(livenessProvider, (previous, next) {
      if (next.status == LivenessStatus.success && !_successDialogShown) {
        _successDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSuccessDialog();
        });
      }
      if (next.status == LivenessStatus.failure &&
          previous?.status != LivenessStatus.failure &&
          next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFailureDialog(next.errorMessage!);
        });
      }
    });

    final showingPreview = livenessState.status == LivenessStatus.imageCaptured ||
        livenessState.status == LivenessStatus.checkingLiveness ||
        livenessState.status == LivenessStatus.failure;

    return Scaffold(
      backgroundColor: Colors.black,
      body: showingPreview && _capturedImage != null
          ? _buildPreview(livenessState)
          : _buildCameraView(livenessState),
    );
  }

  Widget _buildCameraView(LivenessState livenessState) {
    return Stack(
      children: [
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(child: CameraPreview(_cameraController!))
        else
          Container(
            color: Colors.grey[900],
            child: const Center(child: AppLoadingIndicator()),
          ),
        CustomPaint(
          painter: FaceOverlayPainter(faceDetected: false),
          child: Container(),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white,
                      size: AppLayout.scaleWidth(context, 30)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 8))),
              child: Text(
                'Look straight at the camera to verify it\'s really you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppLayout.fontSize(context, 14),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isCameraInitialized ? _capturePhoto : null,
                child: Container(
                  width: AppLayout.scaleWidth(context, 70),
                  height: AppLayout.scaleWidth(context, 70),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(AppLayout.scaleWidth(context, 6)),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                'Tap to capture',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: AppLayout.fontSize(context, 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(LivenessState livenessState) {
    final image = _capturedImage!;
    final isSubmitting = livenessState.isSubmitting;

    return Stack(
      children: [
        SizedBox.expand(
          child: kIsWeb
              ? Image.network(image.path, fit: BoxFit.cover)
              : Image.file(File(image.path), fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.15)),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white,
                      size: AppLayout.scaleWidth(context, 30)),
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 24)),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : _retake,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14)),
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 28)),
                      ),
                    ),
                    child: const Text('Retake',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 16)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 28)),
                      ),
                    ),
                    child: isSubmitting
                        ? const AppLoadingIndicator.button()
                        : const Text('Continue',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoadingIndicator(),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  Text(
                    'Verifying...',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: AppLayout.fontSize(context, 16)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 20))),
        contentPadding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: BoxDecoration(
                color: const Color(0xFF069494).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: const Color(0xFF069494),
                  size: AppLayout.scaleWidth(context, 50)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Text(
              'Identity Verified!',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Text(
              'We\'ve confirmed it\'s really you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.grey[600]),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Same KYC contract as the existing (mock) selfie step —
                  // see selfie_capture_screen.dart's identical success
                  // handler — so KycFlowManager never re-routes the user
                  // back to this step on re-entry.
                  await ref.read(authProvider.notifier).updateKycStatus(
                        isSelfieVerified: true,
                      );

                  if (context.mounted) {
                    Navigator.pop(context); // close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IdVerificationScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 12)),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: AppLayout.fontSize(context, 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 16))),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Verification Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _retake();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
