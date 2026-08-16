// lib/model/identity/liveness_response.dart
//
// Models Dojah's Liveness Check response — POST /api/v1/ml/liveness.
// Schema confirmed 2026-08-12 against Dojah's published API reference
// (docs.dojah.io/api-reference/biometrics-liveness/liveness-check).
//
// Every field below except the two top-level containers (LivenessResponse
// .entity, LivenessDetails.face/.liveness) is nullable — Dojah does not
// guarantee every attribute is present on every response (e.g. a low-quality
// image can come back with `face` populated but several `details.*`
// attributes missing), so nothing here may be force-unwrapped by callers.

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return null;
}

/// Top-level Dojah liveness API response: `{ "entity": { ... } }`.
class LivenessResponse {
  final LivenessDetails? entity;

  const LivenessResponse({this.entity});

  factory LivenessResponse.fromJson(Map<String, dynamic> json) {
    final entityJson = json['entity'];
    return LivenessResponse(
      entity: entityJson is Map<String, dynamic>
          ? LivenessDetails.fromJson(entityJson)
          : null,
    );
  }

  // ── Convenience accessors — the minimum set the app needs to decide UI ────
  bool? get faceDetected => entity?.face?.faceDetected;
  bool? get multipleFacesDetected => entity?.face?.multipleFacesDetected;
  bool? get livenessCheck => entity?.liveness?.livenessCheck;
  double? get livenessProbability => entity?.liveness?.livenessProbability;
  double? get faceConfidence => entity?.face?.confidence;
  ImageQuality? get imageQuality => entity?.face?.quality;
}

/// `entity` — the container for the `face` and `liveness` results.
class LivenessDetails {
  final FaceResult? face;
  final LivenessResult? liveness;

  const LivenessDetails({this.face, this.liveness});

  factory LivenessDetails.fromJson(Map<String, dynamic> json) {
    final faceJson = json['face'];
    final livenessJson = json['liveness'];
    return LivenessDetails(
      face: faceJson is Map<String, dynamic>
          ? FaceResult.fromJson(faceJson)
          : null,
      liveness: livenessJson is Map<String, dynamic>
          ? LivenessResult.fromJson(livenessJson)
          : null,
    );
  }
}

/// `entity.liveness` — the actual liveness verdict.
///
/// `livenessCheck == true` is the ONLY success condition this app uses.
/// `livenessProbability` is retained for future business rules/auditing but
/// deliberately not turned into a threshold here — Dojah documents it on a
/// 0-100 scale (not 0-1), so callers must not assume normalization.
class LivenessResult {
  final bool? livenessCheck;
  final double? livenessProbability;

  const LivenessResult({this.livenessCheck, this.livenessProbability});

  factory LivenessResult.fromJson(Map<String, dynamic> json) {
    return LivenessResult(
      livenessCheck: _asBool(json['liveness_check']),
      livenessProbability: _asDouble(json['liveness_probability']),
    );
  }
}

/// `entity.face` — face detection + biometric attributes.
///
/// `details.*` attributes (age range, gender, emotions, etc.) are flattened
/// onto this class rather than modeled as a separate "FaceDetails" wrapper,
/// since the app only ever needs to reach them directly.
class FaceResult {
  final bool? faceDetected;
  final String? message;
  final bool? multipleFacesDetected;
  final double? confidence;
  final BoundingBox? boundingBox;
  final ImageQuality? quality;

  // From `details.*` — sensitive biometric attributes. Retained on the
  // domain model per spec, but must NOT be surfaced in the UI.
  final AgeRange? ageRange;
  final FaceAttribute? smile;
  final FaceAttribute? gender;
  final FaceAttribute? eyeglasses;
  final FaceAttribute? sunglasses;
  final FaceAttribute? beard;
  final FaceAttribute? mustache;
  final FaceAttribute? eyesOpen;
  final FaceAttribute? mouthOpen;
  final List<Emotion>? emotions;

  const FaceResult({
    this.faceDetected,
    this.message,
    this.multipleFacesDetected,
    this.confidence,
    this.boundingBox,
    this.quality,
    this.ageRange,
    this.smile,
    this.gender,
    this.eyeglasses,
    this.sunglasses,
    this.beard,
    this.mustache,
    this.eyesOpen,
    this.mouthOpen,
    this.emotions,
  });

  factory FaceResult.fromJson(Map<String, dynamic> json) {
    final boundingBoxJson = json['bounding_box'];
    final qualityJson = json['quality'];
    final details = json['details'];
    final detailsJson = details is Map<String, dynamic> ? details : null;
    final emotionsJson = detailsJson?['emotions'];

    return FaceResult(
      faceDetected: _asBool(json['face_detected']),
      message: json['message'] as String?,
      multipleFacesDetected: _asBool(json['multiface_detected']),
      confidence: _asDouble(json['confidence']),
      boundingBox: boundingBoxJson is Map<String, dynamic>
          ? BoundingBox.fromJson(boundingBoxJson)
          : null,
      quality: qualityJson is Map<String, dynamic>
          ? ImageQuality.fromJson(qualityJson)
          : null,
      ageRange: detailsJson?['age_range'] is Map<String, dynamic>
          ? AgeRange.fromJson(detailsJson!['age_range'])
          : null,
      smile: FaceAttribute._fromDetails(detailsJson, 'smile'),
      gender: FaceAttribute._fromDetails(detailsJson, 'gender'),
      eyeglasses: FaceAttribute._fromDetails(detailsJson, 'eyeglasses'),
      sunglasses: FaceAttribute._fromDetails(detailsJson, 'sunglasses'),
      beard: FaceAttribute._fromDetails(detailsJson, 'beard'),
      mustache: FaceAttribute._fromDetails(detailsJson, 'mustache'),
      eyesOpen: FaceAttribute._fromDetails(detailsJson, 'eyes_open'),
      mouthOpen: FaceAttribute._fromDetails(detailsJson, 'mouth_open'),
      emotions: emotionsJson is List
          ? emotionsJson
              .whereType<Map<String, dynamic>>()
              .map(Emotion.fromJson)
              .toList()
          : null,
    );
  }
}

/// `entity.face.details.age_range`.
class AgeRange {
  final int? low;
  final int? high;

  const AgeRange({this.low, this.high});

  factory AgeRange.fromJson(Map<String, dynamic> json) {
    return AgeRange(low: _asInt(json['low']), high: _asInt(json['high']));
  }
}

/// Generic `{ value, confidence }` shape shared by several `details.*`
/// entries (smile, gender, eyeglasses, sunglasses, beard, mustache,
/// eyes_open, mouth_open). `value` is left untyped since Dojah returns a
/// bool for most of these but a String for `gender`.
class FaceAttribute {
  final dynamic value;
  final double? confidence;

  const FaceAttribute({this.value, this.confidence});

  factory FaceAttribute.fromJson(Map<String, dynamic> json) {
    return FaceAttribute(
      value: json['value'],
      confidence: _asDouble(json['confidence']),
    );
  }

  static FaceAttribute? _fromDetails(
      Map<String, dynamic>? details, String key) {
    final v = details?[key];
    return v is Map<String, dynamic> ? FaceAttribute.fromJson(v) : null;
  }
}

/// One entry of `entity.face.details.emotions`: `{ type, confidence }`.
class Emotion {
  final String? type;
  final double? confidence;

  const Emotion({this.type, this.confidence});

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      type: json['type'] as String?,
      confidence: _asDouble(json['confidence']),
    );
  }
}

/// `entity.face.quality`.
class ImageQuality {
  final double? brightness;
  final double? sharpness;

  const ImageQuality({this.brightness, this.sharpness});

  factory ImageQuality.fromJson(Map<String, dynamic> json) {
    return ImageQuality(
      brightness: _asDouble(json['brightness']),
      sharpness: _asDouble(json['sharpness']),
    );
  }
}

/// `entity.face.bounding_box` — normalized (0-1) box relative to image size.
class BoundingBox {
  final double? width;
  final double? height;
  final double? left;
  final double? top;

  const BoundingBox({this.width, this.height, this.left, this.top});

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
      left: _asDouble(json['left']),
      top: _asDouble(json['top']),
    );
  }
}
