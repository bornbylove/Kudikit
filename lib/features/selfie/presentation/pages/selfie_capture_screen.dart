import 'package:flutter/material.dart';
import 'package:kudipay/shared/widgets/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/features/selfie/presentation/pages/face_overlay.dart';
import 'package:kudipay/features/identity/presentation/pages/choose_id.dart';
import 'package:permission_handler/permission_handler.dart';

class SelfieCaptureScreen extends ConsumerStatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  ConsumerState<SelfieCaptureScreen> createState() =>
      _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends ConsumerState<SelfieCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();
  bool _successDialogShown = false;
  bool _errorDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
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
        setState(() {
          _isCameraInitialized = true;
        });
        ref.read(selfieStateProvider.notifier).setCameraInitialized(true);
        _simulateFaceDetection();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
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
          'This app needs camera access to capture your selfie. Please grant permission in settings.',
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

  void _simulateFaceDetection() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(selfieStateProvider.notifier).setFaceDetected(true);
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        _processImage(image.path);
      }
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      _processImage(photo.path);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  void _processImage(String imagePath) {
    ref.read(selfieStateProvider.notifier).validateAndUploadImage(imagePath);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selfieState = ref.watch(selfieStateProvider);

    if (selfieState.validationPassed && !_successDialogShown) {
      _successDialogShown = true; // SET FLAG BEFORE showing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }

    if (selfieState.error != null && !_errorDialogShown) {
      _errorDialogShown = true; // SET FLAG BEFORE showing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(selfieState.error!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: AppLoadingIndicator(),
              ),
            ),
          CustomPaint(
            painter: FaceOverlayPainter(
              faceDetected: selfieState.faceDetected,
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
                  if (selfieState.faceDetected)
                    Container(
                      padding:
                          EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                      decoration: BoxDecoration(
                        color: Color(0xFF069494),
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 20)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white,
                              size: AppLayout.scaleWidth(context, 16)),
                          SizedBox(height: AppLayout.scaleWidth(context, 6)),
                          Text(
                            'Face Detected',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: AppLayout.fontSize(context, 12)),
                          ),
                        ],
                      ),
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
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 8))),
                child: Text(
                  'Position your face within the frame',
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
                  onTap: selfieState.isLoading ? null : _capturePhoto,
                  child: Container(
                    width: AppLayout.scaleWidth(context, 70),
                    height: AppLayout.scaleWidth(context, 70),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: selfieState.isLoading
                        ? Padding(
                            padding: EdgeInsets.all(
                                AppLayout.scaleWidth(context, 12)),
                            child: const AppLoadingIndicator.button(),
                          )
                        : Container(
                            margin: EdgeInsets.all(
                                AppLayout.scaleWidth(context, 6)),
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
          if (selfieState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoadingIndicator(),
                    SizedBox(height: AppLayout.scaleHeight(context, 16)),
                    Text(
                      'Validating your photo...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 16)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
                color: Color(0xFF069494).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: Color(0xFF069494),
                  size: AppLayout.scaleWidth(context, 50)),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Text(
              'Photo Verified!',
              style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 24),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Text(
              'Your photo has been successfully validated and uploaded.',
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
                  // Persist selfie verification so KycFlowManager never
                  // re-routes the user back to this step on re-entry.
                  await ref.read(authProvider.notifier).updateKycStatus(
                        isSelfieVerified: true,
                      );

                  if (context.mounted) {
                    // Pop the dialog first, then pushReplacement so the
                    // capture screen is removed — user cannot go back to
                    // the camera after photo is validated and uploaded.
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

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 16))),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            SizedBox(height: AppLayout.scaleWidth(context, 12)),
            const Text('Validation Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _errorDialogShown = false; // RESET FLAG so it can show again
              ref.read(selfieStateProvider.notifier).reset();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
