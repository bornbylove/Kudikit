// lib/core/utils/image_encoding.dart
//
// The KYC endpoints take images as base64 strings inside the JSON body, not as
// multipart uploads:
//
//   verify-bvn / verify-nin  -> selfieImageBase64
//   verify-id-document       -> frontImageBase64, backImageBase64
//   verify-address           -> utilityBillImageBase64
//
// Two things make this worth a dedicated helper rather than an inline
// base64Encode call:
//
//   1. Base64 inflates payloads by ~33%. An unmodified phone camera photo of
//      4 MB becomes a ~5.5 MB JSON string, which will stall or fail against
//      DioClient's 30s send timeout on a mobile connection.
//   2. A failure here should be a clear, catchable error the UI can act on
//      ("photo too large, retake it") rather than a timeout or an opaque 413.
//
// ASSUMPTION TO CONFIRM: emits raw base64 with no `data:image/jpeg;base64,`
// prefix. The spec types these fields as plain strings without saying which,
// and the endpoints require auth so this could not be probed without an
// account. If the backend rejects the payload, the prefix is the first thing
// to try.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Largest raw image accepted before encoding. 3 MB raw ≈ 4 MB of base64.
const int kMaxImageBytes = 3 * 1024 * 1024;

/// Longest edge, in pixels, after downscaling.
///
/// 1080 keeps enough detail for face matching and document OCR — the backend
/// scores these via livenessConfidence / bvnMatchConfidence /
/// idDocumentNameMatchScore, so compressing harder risks lowering those.
const int kMaxImageDimension = 1080;

/// JPEG quality steps. Each is retried in order until the encoded payload fits
/// under the limit, so a large photo degrades gracefully instead of being
/// rejected outright.
const List<int> kQualityLadder = [85, 70, 55];

/// Thrown when an image is too large to send. Carries both sizes so the UI can
/// tell the user how far over they are.
class ImageTooLargeException implements Exception {
  final int actualBytes;
  final int maxBytes;

  const ImageTooLargeException(this.actualBytes, this.maxBytes);

  double get actualMb => actualBytes / (1024 * 1024);
  double get maxMb => maxBytes / (1024 * 1024);

  @override
  String toString() =>
      'Image is ${actualMb.toStringAsFixed(1)} MB — the limit is '
      '${maxMb.toStringAsFixed(1)} MB. Retake or choose a smaller photo.';
}

/// Thrown when the file is missing or empty.
class ImageUnreadableException implements Exception {
  final String path;
  const ImageUnreadableException(this.path);

  @override
  String toString() => 'Could not read image at $path.';
}

/// Encodes raw bytes to base64, enforcing [maxBytes].
///
/// Separated from the [File] variant so the size rule is testable without
/// touching the filesystem.
String encodeImageBytes(Uint8List bytes, {int maxBytes = kMaxImageBytes}) {
  if (bytes.isEmpty) throw const ImageUnreadableException('<empty bytes>');
  if (bytes.length > maxBytes) {
    throw ImageTooLargeException(bytes.length, maxBytes);
  }
  return base64Encode(bytes);
}

/// Reads [file] and encodes it to base64, enforcing [maxBytes].
///
/// Throws [ImageUnreadableException] if the file is absent or empty, and
/// [ImageTooLargeException] if it exceeds the limit.
Future<String> encodeImageFile(
  File file, {
  int maxBytes = kMaxImageBytes,
}) async {
  if (!await file.exists()) throw ImageUnreadableException(file.path);

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) throw ImageUnreadableException(file.path);
  if (bytes.length > maxBytes) {
    throw ImageTooLargeException(bytes.length, maxBytes);
  }
  return base64Encode(bytes);
}

/// Cheap existence/readability check with no encoding.
///
/// Use this at capture time. The size limit is deliberately *not* applied
/// here: compression happens at submit time and brings almost any camera
/// photo under the limit, so rejecting on raw size at capture would refuse
/// images that would have been fine.
Future<void> assertImageReadable(File file) async {
  if (!await file.exists()) throw ImageUnreadableException(file.path);
  if (await file.length() == 0) throw ImageUnreadableException(file.path);
}

/// Encodes [file] when present, otherwise returns null — for optional images
/// such as `backImageBase64` on a single-sided document.
Future<String?> encodeOptionalImageFile(
  File? file, {
  int maxBytes = kMaxImageBytes,
}) async {
  if (file == null) return null;
  return encodeImageFile(file, maxBytes: maxBytes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Compression
// ─────────────────────────────────────────────────────────────────────────────

/// Downscales and re-encodes an image, returning null when the source cannot be
/// compressed (unsupported format, or the plugin is unavailable as in tests).
///
/// Injectable so the surrounding logic can be tested without the platform
/// channel that [FlutterImageCompress] needs.
typedef ImageCompressor = Future<Uint8List?> Function(
  String path, {
  required int quality,
  required int maxDimension,
});

Future<Uint8List?> compressWithPlugin(
  String path, {
  required int quality,
  required int maxDimension,
}) async {
  try {
    return await FlutterImageCompress.compressWithFile(
      path,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );
  } catch (_) {
    // Unsupported format or no platform implementation — the caller falls
    // back to encoding the original file.
    return null;
  }
}

/// Compresses [file] then base64-encodes it, stepping down through
/// [kQualityLadder] until the result fits within [maxBytes].
///
/// This is what the KYC endpoints should use. A camera selfie is routinely
/// 4–8 MB, which base64 inflates past any sane request limit; downscaling to
/// [kMaxImageDimension] brings a typical photo to a few hundred KB.
///
/// If compression is unavailable the original file is encoded instead, so the
/// [maxBytes] guard still applies and behaviour degrades rather than breaking.
Future<String> prepareImageForUpload(
  File file, {
  int maxBytes = kMaxImageBytes,
  int maxDimension = kMaxImageDimension,
  List<int> qualityLadder = kQualityLadder,
  ImageCompressor compressor = compressWithPlugin,
}) async {
  if (!await file.exists()) throw ImageUnreadableException(file.path);

  Uint8List? smallest;

  for (final quality in qualityLadder) {
    final bytes = await compressor(
      file.path,
      quality: quality,
      maxDimension: maxDimension,
    );
    if (bytes == null || bytes.isEmpty) break;

    smallest = bytes;
    if (bytes.length <= maxBytes) return base64Encode(bytes);
  }

  // Compression unavailable — fall back to the original file.
  if (smallest == null) return encodeImageFile(file, maxBytes: maxBytes);

  // Compressed as far as the ladder goes and it still does not fit.
  throw ImageTooLargeException(smallest.length, maxBytes);
}

/// [prepareImageForUpload] for an optional image, e.g. `backImageBase64`.
Future<String?> prepareOptionalImageForUpload(
  File? file, {
  int maxBytes = kMaxImageBytes,
  int maxDimension = kMaxImageDimension,
  List<int> qualityLadder = kQualityLadder,
  ImageCompressor compressor = compressWithPlugin,
}) async {
  if (file == null) return null;
  return prepareImageForUpload(
    file,
    maxBytes: maxBytes,
    maxDimension: maxDimension,
    qualityLadder: qualityLadder,
    compressor: compressor,
  );
}
