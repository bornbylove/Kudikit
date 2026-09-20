// integration_test/image_compression_test.dart
//
// Exercises the REAL flutter_image_compress plugin through ImageBase64Util —
// `flutter test` can't (no platform channel there), so the size-ladder logic
// is unit-tested with an injected compressor in test/image_base64_util_test.dart
// and this file pins what the native side actually does. Run on a device or
// emulator:
//
//   flutter test integration_test/image_compression_test.dart -d <device id>

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:integration_test/integration_test.dart';
import 'package:kudipay/core/utils/image_base64_util.dart';

/// A busy synthetic "photo": thousands of random coloured rectangles, so the
/// JPEG doesn't collapse to a few KB the way a flat image would.
Future<Uint8List> _detailedPng(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final random = Random(7);
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFF888888));
  for (var i = 0; i < 60000; i++) {
    canvas.drawRect(
      ui.Rect.fromLTWH(random.nextDouble() * w, random.nextDouble() * h,
          4 + random.nextDouble() * 40, 4 + random.nextDouble() * 40),
      ui.Paint()..color = ui.Color(0xFF000000 | random.nextInt(0xFFFFFF)),
    );
  }
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// A full-resolution JPEG like a phone's gallery photo (no downscaling).
Future<Uint8List> _bigJpeg(int w, int h) async {
  final png = await _detailedPng(w, h);
  return FlutterImageCompress.compressWithList(
    png,
    minWidth: w,
    minHeight: h,
    quality: 98,
    format: CompressFormat.jpeg,
  );
}

/// Inserts an EXIF APP1 segment declaring Orientation = 6 ("rotate 90° CW
/// to display") straight after the JPEG SOI marker — exactly how a phone
/// stores a portrait shot as a landscape raster.
Uint8List _withExifOrientation6(Uint8List jpeg) {
  const app1 = <int>[
    0xFF, 0xE1, 0x00, 0x22, // APP1, length 34
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // TIFF header (big-endian)
    0x00, 0x01, // one IFD0 entry
    0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x06, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, // no next IFD
  ];
  return Uint8List.fromList([...jpeg.sublist(0, 2), ...app1, ...jpeg.sublist(2)]);
}

Future<(int, int)> _dims(Uint8List bytes) async {
  final image = await decodeImageFromList(bytes);
  return (image.width, image.height);
}

bool _isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a large gallery photo is downscaled well under the cap',
      (tester) async {
    await tester.runAsync(() async {
      final original = await _bigJpeg(4000, 3000);
      expect(original.length, greaterThan(2 * 1024 * 1024),
          reason: 'fixture must be big enough to need compressing');

      final sw = Stopwatch()..start();
      final out = await ImageBase64Util.prepareForUpload(original);
      sw.stop();

      expect(_isJpeg(out), isTrue);
      expect(out.length, lessThanOrEqualTo(ImageBase64Util.maxUploadBytes));
      expect(out.length, lessThan(original.length));
      // Short side capped at 1536; aspect ratio kept; never upscaled.
      expect(await _dims(out), (2048, 1536));
      // ignore: avoid_print
      print('PROBE 4000x3000 ${original.length ~/ 1024}KB -> '
          '${out.length ~/ 1024}KB in ${sw.elapsedMilliseconds}ms');
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('a small selfie-sized image is sent byte-for-byte unchanged',
      (tester) async {
    await tester.runAsync(() async {
      final png = await _detailedPng(1280, 720);
      final selfie = await FlutterImageCompress.compressWithList(
        png,
        minWidth: 1280,
        minHeight: 720,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      expect(selfie.length, lessThanOrEqualTo(
          ImageBase64Util.skipCompressionBelowBytes),
          reason: 'fixture must be under the skip threshold');

      final out = await ImageBase64Util.prepareForUpload(selfie);

      expect(out, selfie);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('EXIF rotation is baked in — a portrait shot is not uploaded '
      'sideways', (tester) async {
    await tester.runAsync(() async {
      // Raster is landscape (4000x3000) but EXIF says "display rotated 90°",
      // i.e. the photo was taken in portrait.
      final raster = await _bigJpeg(4000, 3000);
      final portraitShot = _withExifOrientation6(raster);

      final out = await ImageBase64Util.prepareForUpload(portraitShot);

      final (w, h) = await _dims(out);
      expect(h, greaterThan(w),
          reason: 'EXIF orientation was dropped without rotating the pixels, '
              'so the server would receive a sideways image ($w x $h)');
      expect((w, h), (1536, 2048));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('encodeToBase64 compresses via the real plugin end to end',
      (tester) async {
    await tester.runAsync(() async {
      final original = await _bigJpeg(4000, 3000);
      final file = XFile.fromData(original, name: 'id_front.jpg');

      final encoded = await ImageBase64Util.encodeToBase64(file);

      // ~2.7 MB of base64 is the ceiling for a 2 MB image.
      expect(encoded.length, lessThan(3 * 1024 * 1024));
      expect(encoded.startsWith('data:'), isFalse);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
