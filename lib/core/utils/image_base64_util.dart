// lib/core/utils/image_base64_util.dart
//
// Dedicated read -> (downscale) -> base64 -> strip-prefix utility for image
// payloads sent to the auth-service KYC APIs (selfie with BVN/NIN, ID
// documents, utility bills). Kept out of UI widgets so this logic exists in
// exactly one place — every KYC upload goes through [encodeToBase64].
//
// Built on XFile.readAsBytes() rather than dart:io File — XFile (already
// used throughout this app's selfie/camera flow, re-exported by both the
// `camera` and `image_picker` packages) works on both native and web, and
// dart:io File does not exist on Flutter web.
//
// WHY COMPRESS: the KYC endpoints take images as base64 inside a JSON body.
// The ID document and utility bill come from the gallery via FilePicker, i.e.
// full-resolution phone photos of several MB, and base64 adds another third
// on top. That has to cross a mobile connection inside DioClient's 30 s send
// timeout — the backend itself enforces no size limit (only @NotBlank), so the
// timeout is the real ceiling. The selfie camera runs at 720p and is normally
// already small, so it passes through untouched.
//
// HOW: flutter_image_compress (native — fast, and it samples while decoding
// so a huge photo doesn't need its full bitmap in RAM, which matters on the
// low-memory Android phones a pure-Dart decoder would struggle on). Verified
// on an Android emulator (integration_test/image_compression_test.dart): a
// 12 MP / 6.6 MB photo becomes ~1.2 MB in ~0.1-0.5 s, EXIF rotation is baked
// in, and it never upscales. NOT yet verified on iOS: the app can't build for
// the arm64 iOS simulator (google_mlkit_face_detection has no arm64 simulator
// slice), so run that test on a physical iPhone before relying on it there.
// NOTE the plugin's min{Width,Height} set the SHORT side of the result, so a
// square `minSize` of 1536 turns 4000x3000 into 2048x1536 and 3000x4000 into
// 1536x2048.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:kudipay/config/dio_client.dart' show KudiApiException;

/// Re-encodes [bytes] as a JPEG whose short side is at most [minSize] pixels.
/// Injectable so the size-ladder logic can be unit tested without the native
/// plugin.
typedef ImageCompressFn = Future<Uint8List> Function(
  Uint8List bytes, {
  required int minSize,
  required int quality,
});

Future<Uint8List> _nativeCompress(
  Uint8List bytes, {
  required int minSize,
  required int quality,
}) {
  return FlutterImageCompress.compressWithList(
    bytes,
    minWidth: minSize,
    minHeight: minSize,
    quality: quality,
    format: CompressFormat.jpeg,
  );
}

/// Thrown when an image can't be brought under [ImageBase64Util.maxUploadBytes].
///
/// A [KudiApiException] so every KYC screen — which already shows the message
/// of any KudiApiException — displays it, instead of "Something went wrong".
class ImageTooLargeException implements KudiApiException {
  @override
  final String message;
  final int actualBytes;
  final int maxBytes;

  ImageTooLargeException({required this.actualBytes, required this.maxBytes})
      : message = 'This photo is too large to upload. Please choose a smaller '
            'photo or retake it.';

  @override
  int? get statusCode => null;

  @override
  String toString() => message;
}

class ImageBase64Util {
  ImageBase64Util._();

  static final RegExp _dataUriPrefix =
      RegExp(r'^data:image\/[a-zA-Z0-9.+-]+;base64,');

  /// Images at or below this are sent exactly as captured — no recompression
  /// quality loss for the already-small 720p selfie.
  static const int skipCompressionBelowBytes = 900 * 1024;

  /// Hard cap on the bytes sent per image (~2.7 MB once base64-encoded).
  static const int maxUploadBytes = 2 * 1024 * 1024;

  /// Compression attempts, in order: (short-side pixels, JPEG quality). 1536
  /// keeps an A4 utility bill legible (~185 dpi) and an ID card sharp; the
  /// later steps only run for photos that are still over the cap.
  static const List<(int, int)> compressionLadder = [
    (1536, 85),
    (1536, 75),
    (1536, 65),
    (1024, 65),
  ];

  /// Reads [file]'s bytes, downscales/recompresses them if they are large,
  /// and returns a raw base64 string with no `data:image/...;base64,` prefix —
  /// ready to send as-is in an auth-service KYC request body.
  ///
  /// Throws [ImageTooLargeException] if the image can't be made small enough.
  static Future<String> encodeToBase64(
    XFile file, {
    ImageCompressFn? compress,
  }) async {
    final bytes = await file.readAsBytes();
    return base64Encode(await prepareForUpload(bytes, compress: compress));
  }

  /// The bytes that will actually be uploaded for [bytes].
  ///
  /// Small images are returned unchanged. Larger ones walk
  /// [compressionLadder] until one fits under [maxUploadBytes]. If compression
  /// fails outright (unsupported format, plugin error) the original is used
  /// when it is already within the cap, so a compression problem never blocks
  /// a submission that would have fit.
  static Future<Uint8List> prepareForUpload(
    Uint8List bytes, {
    ImageCompressFn? compress,
  }) async {
    if (bytes.length <= skipCompressionBelowBytes) return bytes;

    final run = compress ?? _nativeCompress;
    for (final (minSize, quality) in compressionLadder) {
      try {
        final out = await run(bytes, minSize: minSize, quality: quality);
        if (out.isNotEmpty && out.length <= maxUploadBytes) return out;
      } catch (_) {
        break; // fall through to the original-if-it-fits check below
      }
    }

    if (bytes.length <= maxUploadBytes) return bytes;
    throw ImageTooLargeException(
        actualBytes: bytes.length, maxBytes: maxUploadBytes);
  }

  /// Strips a `data:image/...;base64,` prefix if present. Safe to call on a
  /// string that already has no prefix — returned unchanged.
  static String stripDataUriPrefix(String value) {
    return value.replaceFirst(_dataUriPrefix, '');
  }
}
