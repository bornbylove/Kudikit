// test/liveness_response_test.dart
//
// Parsing tests for the Dojah liveness response models. The "full" fixture
// below is Dojah's own published sample response (docs.dojah.io/api-reference
// /biometrics-liveness/liveness-check) — not invented data.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/identity/liveness_response.dart';

final Map<String, dynamic> _fullDojahSample = {
  'entity': {
    'face': {
      'face_detected': true,
      'message': 'face detected',
      'multiface_detected': false,
      'details': {
        'age_range': {'low': 21, 'high': 27},
        'smile': {'value': false, 'confidence': 99.40308380126953},
        'gender': {'value': 'Male', 'confidence': 99.94355773925781},
        'eyeglasses': {'value': false, 'confidence': 99.33769989013672},
        'sunglasses': {'value': false, 'confidence': 99.07188415527344},
        'beard': {'value': true, 'confidence': 99.83099365234375},
        'mustache': {'value': true, 'confidence': 94.46673583984375},
        'eyes_open': {'value': true, 'confidence': 98.43293762207031},
        'mouth_open': {'value': false, 'confidence': 95.88761901855469},
        'emotions': [
          {'type': 'CALM', 'confidence': 98.60491180419922},
          {'type': 'SAD', 'confidence': 0.7328033447265625},
        ],
      },
      'quality': {
        'brightness': 54.561920166015625,
        'sharpness': 83.14741516113281,
      },
      'confidence': 99.99991607666016,
      'bounding_box': {
        'width': 0.4428365230560303,
        'height': 0.30233171582221985,
        'left': 0.2544552981853485,
        'top': 0.3601169288158417,
      },
    },
    'liveness': {
      'liveness_check': true,
      'liveness_probability': 98,
    },
  },
};

void main() {
  group('LivenessResponse.fromJson', () {
    test('parses the full documented Dojah sample response', () {
      final response = LivenessResponse.fromJson(_fullDojahSample);

      expect(response.faceDetected, true);
      expect(response.multipleFacesDetected, false);
      expect(response.livenessCheck, true);
      expect(response.livenessProbability, 98);
      expect(response.faceConfidence, closeTo(99.99991, 0.001));
      expect(response.imageQuality?.brightness, closeTo(54.5619, 0.001));
      expect(response.imageQuality?.sharpness, closeTo(83.1474, 0.001));

      final face = response.entity!.face!;
      expect(face.ageRange?.low, 21);
      expect(face.ageRange?.high, 27);
      expect(face.gender?.value, 'Male');
      expect(face.beard?.value, true);
      expect(face.emotions, hasLength(2));
      expect(face.emotions?.first.type, 'CALM');
      expect(face.boundingBox?.left, closeTo(0.2544, 0.001));
    });

    test('liveness_check == false is preserved as failure, not thrown', () {
      final json = {
        'entity': {
          'face': {'face_detected': true},
          'liveness': {'liveness_check': false, 'liveness_probability': 12},
        },
      };

      final response = LivenessResponse.fromJson(json);

      expect(response.livenessCheck, false);
      expect(response.livenessProbability, 12);
    });

    test('handles a response with only the required entity/face/liveness shell',
        () {
      final Map<String, dynamic> json = {
        'entity': <String, dynamic>{
          'face': <String, dynamic>{},
          'liveness': <String, dynamic>{},
        },
      };

      final response = LivenessResponse.fromJson(json);

      expect(response.faceDetected, isNull);
      expect(response.livenessCheck, isNull);
      expect(response.faceConfidence, isNull);
      expect(response.entity!.face!.ageRange, isNull);
      expect(response.entity!.face!.emotions, isNull);
    });

    test('handles entirely missing optional sections without throwing', () {
      final response =
          LivenessResponse.fromJson(<String, dynamic>{'entity': <String, dynamic>{}});

      expect(response.entity, isNotNull);
      expect(response.entity!.face, isNull);
      expect(response.entity!.liveness, isNull);
      expect(response.faceDetected, isNull);
      expect(response.livenessCheck, isNull);
    });

    test('handles a malformed response with no entity key at all', () {
      final response = LivenessResponse.fromJson({'unexpected': 'shape'});

      expect(response.entity, isNull);
      expect(response.livenessCheck, isNull);
      expect(response.faceDetected, isNull);
    });

    test('gender FaceAttribute keeps its String value distinct from bool attributes',
        () {
      final response = LivenessResponse.fromJson(_fullDojahSample);
      final face = response.entity!.face!;

      expect(face.gender?.value, isA<String>());
      expect(face.smile?.value, isA<bool>());
    });
  });
}
