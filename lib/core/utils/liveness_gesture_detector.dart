// lib/core/utils/liveness_gesture_detector.dart
//
// On-device active-liveness challenge for the selfie capture step. This is a
// CLIENT-SIDE ANTI-SPOOFING GATE ONLY: it decides whether the shutter button
// unlocks, nothing more. It never sets, claims, or persists a "liveness
// verified" result — that authority stays entirely server-side in
// kudikit_auth_service (DojahIdentityClient), matching the existing contract
// documented in LivenessState/LivenessNotifier. This class is intentionally
// NOT wired into livenessProvider for that reason.
//
// Sequence: turn head left -> turn head right -> open mouth. Each step
// requires the condition to hold for several consecutive frames (debounce)
// before advancing, to avoid a single noisy frame flipping state.
//
// NOTE: the turn-left/turn-right angle threshold and the mouth-open ratio
// threshold below are reasonable starting points, not calibrated on a real
// device. They will likely need tuning once tested on hardware (lighting,
// camera distance, and front-camera mirroring all affect them).

import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum LivenessGesture { turnLeft, turnRight, openMouth }

extension LivenessGesturePrompt on LivenessGesture {
  String get prompt {
    switch (this) {
      case LivenessGesture.turnLeft:
        return 'Slowly turn your head to the left';
      case LivenessGesture.turnRight:
        return 'Slowly turn your head to the right';
      case LivenessGesture.openMouth:
        return 'Open your mouth';
    }
  }
}

class LivenessGestureController extends ChangeNotifier {
  LivenessGestureController({required this.camera})
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableClassification: false,
            enableTracking: false,
            // headEulerAngleY is only reliable in accurate mode (fast mode
            // takes shortcuts that skip it).
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  static const List<LivenessGesture> _sequence = [
    LivenessGesture.turnLeft,
    LivenessGesture.turnRight,
    LivenessGesture.openMouth,
  ];

  // Needs on-device calibration.
  static const double _turnAngleThresholdDegrees = 18.0;
  static const double _mouthOpenRatioThreshold = 0.055;
  static const int _requiredConsecutiveHits = 4;

  final CameraDescription camera;
  final FaceDetector _faceDetector;

  int _stepIndex = 0;
  int _consecutiveHits = 0;
  bool _busy = false;
  bool _disposed = false;
  bool _faceVisible = false;

  LivenessGesture? get currentGesture =>
      _stepIndex < _sequence.length ? _sequence[_stepIndex] : null;

  bool get isComplete => _stepIndex >= _sequence.length;

  bool get faceVisible => _faceVisible;

  String get promptText =>
      currentGesture?.prompt ?? 'Verified — hold still to capture';

  /// Feeds one camera frame through the detector. Frames are dropped while a
  /// previous frame is still being processed, so this is safe to call on
  /// every frame from [CameraController.startImageStream].
  Future<void> processCameraImage(
    CameraImage image,
    DeviceOrientation deviceOrientation,
  ) async {
    if (_busy || _disposed || isComplete) return;
    _busy = true;
    try {
      final inputImage =
          _inputImageFromCameraImage(image, camera, deviceOrientation);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (_disposed) return;

      _faceVisible = faces.isNotEmpty;
      if (faces.isEmpty) {
        notifyListeners();
        return;
      }

      _evaluate(faces.first);
      notifyListeners();
    } catch (e) {
      debugPrint('[LivenessGesture] processCameraImage error: $e');
    } finally {
      _busy = false;
    }
  }

  void _evaluate(Face face) {
    final gesture = currentGesture;
    if (gesture == null) return;

    final passed = switch (gesture) {
      LivenessGesture.turnLeft => (face.headEulerAngleY ?? 0) <
          -_turnAngleThresholdDegrees,
      LivenessGesture.turnRight => (face.headEulerAngleY ?? 0) >
          _turnAngleThresholdDegrees,
      LivenessGesture.openMouth => _isMouthOpen(face),
    };

    if (passed) {
      _consecutiveHits++;
      if (_consecutiveHits >= _requiredConsecutiveHits) {
        _stepIndex++;
        _consecutiveHits = 0;
      }
    } else {
      _consecutiveHits = 0;
    }
  }

  bool _isMouthOpen(Face face) {
    final upperLipBottom = face.contours[FaceContourType.upperLipBottom];
    final lowerLipTop = face.contours[FaceContourType.lowerLipTop];
    if (upperLipBottom == null ||
        lowerLipTop == null ||
        upperLipBottom.points.isEmpty ||
        lowerLipTop.points.isEmpty) {
      return false;
    }

    final faceHeight = face.boundingBox.height;
    if (faceHeight <= 0) return false;

    // Average vertical gap between the two lip contours, normalized by face
    // height so it stays roughly distance-independent.
    final count = upperLipBottom.points.length < lowerLipTop.points.length
        ? upperLipBottom.points.length
        : lowerLipTop.points.length;
    double totalGap = 0;
    for (var i = 0; i < count; i++) {
      totalGap += (lowerLipTop.points[i].y - upperLipBottom.points[i].y);
    }
    final avgGap = totalGap / count;
    return (avgGap / faceHeight) > _mouthOpenRatioThreshold;
  }

  void reset() {
    _stepIndex = 0;
    _consecutiveHits = 0;
    _faceVisible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _faceDetector.close();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CameraImage -> InputImage conversion.
//
// google_mlkit_commons has no built-in CameraImage bridge, so this follows
// the standard rotation-compensation approach used across camera+ML Kit
// Flutter integrations: derive InputImageRotation from sensor orientation
// (iOS) or sensor orientation + device orientation (Android), then wrap the
// single-plane buffer (requires the CameraController to stream nv21 on
// Android / bgra8888 on iOS — see liveness_capture_screen.dart).
// ─────────────────────────────────────────────────────────────────────────────

const Map<DeviceOrientation, int> _deviceOrientationDegrees = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

InputImage? _inputImageFromCameraImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  } else if (Platform.isAndroid) {
    final degrees = _deviceOrientationDegrees[deviceOrientation];
    if (degrees == null) return null;
    int rotationCompensation;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (camera.sensorOrientation + degrees) % 360;
    } else {
      rotationCompensation =
          (camera.sensorOrientation - degrees + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  final isExpectedFormat = Platform.isAndroid
      ? format == InputImageFormat.nv21
      : format == InputImageFormat.bgra8888;
  if (format == null || !isExpectedFormat) return null;

  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
