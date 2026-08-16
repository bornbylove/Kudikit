// lib/core/utils/image_base64_util.dart
//
// Dedicated read -> base64 -> strip-prefix utility for image payloads sent
// to third-party APIs (currently Dojah liveness). Kept out of UI widgets so
// this logic exists in exactly one place.
//
// Built on XFile.readAsBytes() rather than dart:io File — XFile (already
// used throughout this app's selfie/camera flow, re-exported by both the
// `camera` and `image_picker` packages) works on both native and web, and
// dart:io File does not exist on Flutter web.

import 'dart:convert';

import 'package:image_picker/image_picker.dart' show XFile;

class ImageBase64Util {
  ImageBase64Util._();

  static final RegExp _dataUriPrefix =
      RegExp(r'^data:image\/[a-zA-Z0-9.+-]+;base64,');

  /// Reads [file]'s bytes and returns a raw base64 string with no
  /// `data:image/...;base64,` prefix — ready to send as-is in a Dojah
  /// request body.
  static Future<String> encodeToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Strips a `data:image/...;base64,` prefix if present. Safe to call on a
  /// string that already has no prefix — returned unchanged.
  static String stripDataUriPrefix(String value) {
    return value.replaceFirst(_dataUriPrefix, '');
  }
}
