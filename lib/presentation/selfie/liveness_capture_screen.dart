// lib/presentation/selfie/liveness_capture_screen.dart
//
// Selfie capture screen for KYC onboarding. Camera/permission handling mirrors
// SelfieCaptureScreen in this same directory (front camera preferred via
// CameraController, image_picker as a fallback, permission_handler for
// graceful permission requests).
//
// Flow: Capturing (camera) -> ImageCaptured (preview, retake/continue) ->
// IdVerificationScreen (BVN/NIN).
//
// This step only captures the selfie. It performs NO liveness check and makes
// NO KYC provider calls — the authoritative liveness + selfie/registry match
// happens server-side when the selfie is submitted with BVN/NIN (POST
// /auth/kyc/verify-bvn | verify-nin in kudikit_auth_service). The captured
// image is retained in livenessProvider.imagePath for that submission.
//
// NOTE for testing: KYC verification calls the auth-service, which (like any
// third-party-backed API) is very likely to reject or block browser-origin
// requests. This screen should be exercised on a native Android/iOS device or
// emulator, not Chrome.

import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:kudipay/core/utils/liveness_gesture_detector.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:kudipay/model/identity/liveness_state.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
import 'package:kudipay/presentation/selfie/face_overlay.dart';
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

  // Client-side active-liveness gate (turn head left/right, open mouth)
  // before the shutter unlocks. This is anti-spoofing UX only — it never
  // claims an authoritative liveness result; that stays server-side (see
  // liveness_gesture_detector.dart).
  LivenessGestureController? _gestureController;
  bool _imageStreamActive = false;

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
        // takePicture() always returns a JPEG regardless of this setting —
        // this only controls the startImageStream() buffer format, which
        // must be a single-plane format ML Kit's InputImage.fromBytes can
        // consume directly (see liveness_gesture_detector.dart).
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      _gestureController = LivenessGestureController(camera: frontCamera)
        ..addListener(_onGestureUpdate);
      await _cameraController!.startImageStream(_onCameraFrame);
      _imageStreamActive = true;

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

  void _onCameraFrame(CameraImage image) {
    final controller = _cameraController;
    final gestureController = _gestureController;
    if (controller == null || gestureController == null) return;
    gestureController.processCameraImage(image, controller.value.deviceOrientation);
  }

  void _onGestureUpdate() {
    if (!mounted) return;
    if (_gestureController?.isComplete ?? false) {
      _stopImageStream();
    }
    setState(() {});
  }

  Future<void> _stopImageStream() async {
    if (!_imageStreamActive) return;
    _imageStreamActive = false;
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
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

  Future<void> _retake() async {
    setState(() => _capturedImage = null);
    ref.read(livenessProvider.notifier).retake();

    // Re-arm the liveness gesture challenge for the new attempt.
    _gestureController?.reset();
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized && !_imageStreamActive) {
      _imageStreamActive = true;
      await controller.startImageStream(_onCameraFrame);
    }
  }

  /// Confirms the captured selfie and proceeds to ID selection (BVN/NIN).
  /// No liveness call is made here — liveness + selfie/registry matching are
  /// performed by the auth-service when the selfie is submitted with BVN/NIN.
  void _submit() {
    final image = _capturedImage;
    if (image == null) return;
    // The image path is retained in livenessProvider (set on capture) for the
    // BVN/NIN submission step (IdVerificationController.verifyId).
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const IdVerificationScreen()),
    );
  }

  @override
  void dispose() {
    _gestureController?.removeListener(_onGestureUpdate);
    _gestureController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livenessState = ref.watch(livenessProvider);
    final showingPreview = livenessState.status == LivenessStatus.imageCaptured;

    return Scaffold(
      backgroundColor: Colors.black,
      body: showingPreview && _capturedImage != null
          ? _buildPreview()
          : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
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
          painter: FaceOverlayPainter(
            faceDetected: _gestureController?.faceVisible ?? false,
          ),
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
                _gestureController?.promptText ?? 'Look straight at the camera',
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
              Builder(builder: (context) {
                final gesturesComplete = _gestureController?.isComplete ?? false;
                final canCapture = _isCameraInitialized && gesturesComplete;
                return Opacity(
                  opacity: canCapture ? 1.0 : 0.4,
                  child: GestureDetector(
                    onTap: canCapture ? _capturePhoto : null,
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
                );
              }),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                (_gestureController?.isComplete ?? false)
                    ? 'Tap to capture'
                    : 'Complete the steps above to unlock capture',
                textAlign: TextAlign.center,
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

  Widget _buildPreview() {
    final image = _capturedImage!;

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
                  onPressed: () => Navigator.pop(context),
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
                    onPressed: _retake,
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      padding: EdgeInsets.symmetric(
                          vertical: AppLayout.scaleHeight(context, 14)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 28)),
                      ),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
