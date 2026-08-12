// lib/core/utils/face_check.dart
//
// On-device sanity check on a captured selfie, run before it is submitted.
//
// This is NOT a liveness check and must not be presented as one — it cannot
// tell a live person from a photograph of one. Liveness is decided server-side
// by Dojah (POST /api/v1/ml/liveness), which scores the image and passes at
// 90%.
//
// The point of doing anything on-device is to reject captures that obviously
// cannot pass — no face, several faces, eyes shut, face too small in frame —
// before spending a network round trip and a billed API call, and to give the
// user an immediate, specific reason to retake.

import 'dart:io';

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Smallest share of the frame width a face may occupy. Dojah scores
/// sharpness, and a face far from the camera survives downscaling badly.
const double kMinFaceWidthRatio = 0.2;

/// Below this, ML Kit considers the eye closed.
const double kEyeOpenThreshold = 0.3;

class FaceCheckResult {
  final bool passed;

  /// User-facing reason to retake, or null when [passed].
  final String? reason;

  const FaceCheckResult.ok()
      : passed = true,
        reason = null;
  const FaceCheckResult.failed(this.reason) : passed = false;
}

/// Checks that [image] contains exactly one reasonably framed, eyes-open face.
///
/// Returns [FaceCheckResult.ok] when the detector cannot run at all — a
/// missing model or an unsupported platform must not block the user, since
/// the authoritative check happens server-side regardless.
Future<FaceCheckResult> checkSelfie(File image) async {
  final detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // needed for eye-open probabilities
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  try {
    final faces = await detector.processImage(InputImage.fromFile(image));

    if (faces.isEmpty) {
      return const FaceCheckResult.failed(
        'No face detected. Hold the phone at eye level with your face in the '
        'oval.',
      );
    }
    if (faces.length > 1) {
      return const FaceCheckResult.failed(
        'More than one face in frame. Make sure you are alone in the photo.',
      );
    }

    final face = faces.first;

    final decoded = await _imageWidth(image);
    if (decoded != null) {
      final ratio = face.boundingBox.width / decoded;
      if (ratio < kMinFaceWidthRatio) {
        return const FaceCheckResult.failed(
          'Move closer so your face fills the oval.',
        );
      }
    }

    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left != null &&
        right != null &&
        left < kEyeOpenThreshold &&
        right < kEyeOpenThreshold) {
      return const FaceCheckResult.failed(
        'Your eyes look closed. Please look at the camera and retake.',
      );
    }

    return const FaceCheckResult.ok();
  } catch (_) {
    // Detector unavailable — defer to the server rather than blocking.
    return const FaceCheckResult.ok();
  } finally {
    await detector.close();
  }
}

Future<double?> _imageWidth(File image) async {
  try {
    final decoded = await decodeImageFromList(await image.readAsBytes());
    return decoded.width.toDouble();
  } catch (_) {
    return null;
  }
}
