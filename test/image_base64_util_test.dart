// test/image_base64_util_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/config/dio_client.dart' show KudiApiException;
import 'package:kudipay/core/utils/image_base64_util.dart';

void main() {
  group('ImageBase64Util.stripDataUriPrefix', () {
    test('strips a data:image/jpeg;base64, prefix', () {
      final stripped =
          ImageBase64Util.stripDataUriPrefix('data:image/jpeg;base64,AAAA');
      expect(stripped, 'AAAA');
    });

    test('strips a data:image/png;base64, prefix', () {
      final stripped =
          ImageBase64Util.stripDataUriPrefix('data:image/png;base64,BBBB');
      expect(stripped, 'BBBB');
    });

    test('leaves an already-raw base64 string unchanged', () {
      const raw = 'AAAABBBBCCCC==';
      expect(ImageBase64Util.stripDataUriPrefix(raw), raw);
    });
  });

  group('ImageBase64Util.encodeToBase64', () {
    test('reads bytes from an XFile and returns a raw base64 string', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final file = XFile.fromData(bytes, name: 'selfie.jpg');

      final encoded = await ImageBase64Util.encodeToBase64(file);

      expect(encoded, base64Encode(bytes));
      expect(encoded.startsWith('data:'), isFalse);
    });

    test('round-trips back to the original bytes', () async {
      final bytes = Uint8List.fromList(List.generate(64, (i) => i));
      final file = XFile.fromData(bytes, name: 'selfie.jpg');

      final encoded = await ImageBase64Util.encodeToBase64(file);

      expect(base64Decode(encoded), bytes);
    });
  });

  // The native compressor itself is exercised on a device/emulator in
  // integration_test/image_compression_test.dart; here it is replaced so the
  // size-ladder logic can run under `flutter test`.
  group('ImageBase64Util.prepareForUpload', () {
    Uint8List sized(int bytes) => Uint8List(bytes);
    const kb = 1024;
    final small = sized(300 * kb); // e.g. the 720p selfie
    final large = sized(6 * 1024 * kb); // e.g. a 12 MP gallery photo

    /// Records each (minSize, quality) attempt and answers with [sizes] in
    /// order (the last answer repeats).
    ({ImageCompressFn fn, List<(int, int)> calls}) fakeCompressor(
        List<int> sizes) {
      final calls = <(int, int)>[];
      Future<Uint8List> fn(Uint8List bytes,
          {required int minSize, required int quality}) async {
        calls.add((minSize, quality));
        final i = calls.length - 1;
        return sized(sizes[i < sizes.length ? i : sizes.length - 1]);
      }

      return (fn: fn, calls: calls);
    }

    test('a small image is sent exactly as captured, compressor untouched',
        () async {
      final c = fakeCompressor([1]);

      final out = await ImageBase64Util.prepareForUpload(small, compress: c.fn);

      expect(identical(out, small), isTrue);
      expect(c.calls, isEmpty);
    });

    test('the skip threshold is inclusive', () async {
      final atLimit = sized(ImageBase64Util.skipCompressionBelowBytes);
      final c = fakeCompressor([1]);

      await ImageBase64Util.prepareForUpload(atLimit, compress: c.fn);

      expect(c.calls, isEmpty);
    });

    test('a large image is downscaled once when the first step fits',
        () async {
      final c = fakeCompressor([700 * kb]);

      final out = await ImageBase64Util.prepareForUpload(large, compress: c.fn);

      expect(out.length, 700 * kb);
      expect(c.calls, [(1536, 85)]);
    });

    test('steps down quality, then size, until the result fits the cap',
        () async {
      const over = 3 * 1024 * 1024; // still over the 2 MB cap
      final c = fakeCompressor([over, over, over, 900 * kb]);

      final out = await ImageBase64Util.prepareForUpload(large, compress: c.fn);

      expect(out.length, 900 * kb);
      expect(c.calls, [(1536, 85), (1536, 75), (1536, 65), (1024, 65)]);
    });

    test('throws ImageTooLargeException when nothing gets it under the cap',
        () async {
      final c = fakeCompressor([3 * 1024 * 1024]);

      await expectLater(
        ImageBase64Util.prepareForUpload(large, compress: c.fn),
        throwsA(isA<ImageTooLargeException>()
            .having((e) => e.actualBytes, 'actualBytes', large.length)
            .having((e) => e.maxBytes, 'maxBytes', ImageBase64Util.maxUploadBytes)),
      );
      expect(c.calls.length, ImageBase64Util.compressionLadder.length);
    });

    test('ImageTooLargeException is a KudiApiException, so every KYC screen '
        'shows its message', () {
      final e = ImageTooLargeException(actualBytes: 9, maxBytes: 1);
      expect(e, isA<KudiApiException>());
      expect(e.message, contains('too large'));
      expect(e.toString(), e.message);
    });

    test('a compressor failure falls back to the original when it fits the cap',
        () async {
      final fits = sized(1500 * kb); // above the skip threshold, under the cap
      Future<Uint8List> boom(Uint8List b,
              {required int minSize, required int quality}) async =>
          throw Exception('unsupported format');

      final out = await ImageBase64Util.prepareForUpload(fits, compress: boom);

      expect(identical(out, fits), isTrue);
    });

    test('a compressor failure on an over-cap original is a clear error, not '
        'a silent oversize upload', () async {
      Future<Uint8List> boom(Uint8List b,
              {required int minSize, required int quality}) async =>
          throw Exception('plugin missing');

      await expectLater(
        ImageBase64Util.prepareForUpload(large, compress: boom),
        throwsA(isA<ImageTooLargeException>()),
      );
    });

    test('an in-cap original wins when every compressed result is larger',
        () async {
      final fits = sized(1500 * kb);
      final c = fakeCompressor([5 * 1024 * 1024]); // "compression" grew it

      final out = await ImageBase64Util.prepareForUpload(fits, compress: c.fn);

      expect(identical(out, fits), isTrue);
    });

    test('an empty compressor result is ignored', () async {
      final fits = sized(1500 * kb);
      final c = fakeCompressor([0]);

      final out = await ImageBase64Util.prepareForUpload(fits, compress: c.fn);

      expect(identical(out, fits), isTrue);
    });

    test('encodeToBase64 uploads the compressed bytes, base64-encoded',
        () async {
      final c = fakeCompressor([10 * kb]);
      final file = XFile.fromData(large, name: 'id_front.jpg');

      final encoded = await ImageBase64Util.encodeToBase64(file, compress: c.fn);

      expect(base64Decode(encoded).length, 10 * kb);
    });
  });
}
