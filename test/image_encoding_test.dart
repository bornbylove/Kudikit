// test/image_encoding_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/core/utils/image_encoding.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('kyc_image_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  File fileWith(List<int> bytes, {String name = 'img.jpg'}) {
    final f = File('${tmp.path}${Platform.pathSeparator}$name');
    f.writeAsBytesSync(bytes);
    return f;
  }

  group('encodeImageBytes', () {
    test('round-trips to the original bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final encoded = encodeImageBytes(bytes);
      expect(base64Decode(encoded), bytes);
    });

    test('emits raw base64 with no data-URI prefix', () {
      final encoded = encodeImageBytes(Uint8List.fromList([1, 2, 3]));
      expect(encoded.startsWith('data:'), isFalse);
      expect(encoded, base64Encode([1, 2, 3]));
    });

    test('rejects empty bytes', () {
      expect(
        () => encodeImageBytes(Uint8List(0)),
        throwsA(isA<ImageUnreadableException>()),
      );
    });

    test('accepts a payload exactly at the limit', () {
      final bytes = Uint8List(100);
      expect(() => encodeImageBytes(bytes, maxBytes: 100), returnsNormally);
    });

    test('rejects one byte over the limit', () {
      final bytes = Uint8List(101);
      expect(
        () => encodeImageBytes(bytes, maxBytes: 100),
        throwsA(isA<ImageTooLargeException>()),
      );
    });
  });

  group('encodeImageFile', () {
    test('encodes a real file', () async {
      final f = fileWith([10, 20, 30, 40]);
      expect(await encodeImageFile(f), base64Encode([10, 20, 30, 40]));
    });

    test('throws when the file does not exist', () async {
      final missing = File('${tmp.path}${Platform.pathSeparator}nope.jpg');
      expect(
        () => encodeImageFile(missing),
        throwsA(isA<ImageUnreadableException>()),
      );
    });

    test('throws when the file is empty', () async {
      final f = fileWith(const []);
      expect(
        () => encodeImageFile(f),
        throwsA(isA<ImageUnreadableException>()),
      );
    });

    test('throws when the file exceeds the limit', () async {
      final f = fileWith(List.filled(500, 0));
      expect(
        () => encodeImageFile(f, maxBytes: 100),
        throwsA(isA<ImageTooLargeException>()),
      );
    });
  });

  group('encodeOptionalImageFile', () {
    test('returns null for a null file', () async {
      expect(await encodeOptionalImageFile(null), isNull);
    });

    test('encodes when a file is supplied', () async {
      final f = fileWith([7, 7, 7]);
      expect(await encodeOptionalImageFile(f), base64Encode([7, 7, 7]));
    });
  });

  group('ImageTooLargeException message', () {
    test('reports both sizes in MB', () {
      const e = ImageTooLargeException(4 * 1024 * 1024, 3 * 1024 * 1024);
      expect(e.toString(), contains('4.0 MB'));
      expect(e.toString(), contains('3.0 MB'));
    });
  });

  group('base64 inflation', () {
    test('encoded output is roughly 4/3 the raw size', () {
      final encoded = encodeImageBytes(Uint8List(3000));
      // 3000 bytes -> 4000 base64 chars, no padding needed at a multiple of 3.
      expect(encoded.length, 4000);
    });
  });

  group('prepareImageForUpload', () {
    // The real compressor needs a platform channel, so these use a fake that
    // returns a size derived from the requested quality.
    ImageCompressor fakeCompressor(Map<int, int> sizeByQuality,
        {List<int>? seenQualities, List<int>? seenDimensions}) {
      return (String path,
          {required int quality, required int maxDimension}) async {
        seenQualities?.add(quality);
        seenDimensions?.add(maxDimension);
        final size = sizeByQuality[quality];
        return size == null ? null : Uint8List(size);
      };
    }

    test('returns the first compression that fits', () async {
      final seen = <int>[];
      final f = fileWith(List.filled(9000, 1));

      final result = await prepareImageForUpload(
        f,
        maxBytes: 100,
        qualityLadder: const [85, 70, 55],
        compressor:
            fakeCompressor({85: 50, 70: 20, 55: 10}, seenQualities: seen),
      );

      expect(base64Decode(result).length, 50);
      // Stops at the first success — no needless extra passes.
      expect(seen, [85]);
    });

    test('steps down the ladder until it fits', () async {
      final seen = <int>[];
      final f = fileWith(List.filled(9000, 1));

      final result = await prepareImageForUpload(
        f,
        maxBytes: 100,
        qualityLadder: const [85, 70, 55],
        compressor:
            fakeCompressor({85: 500, 70: 300, 55: 90}, seenQualities: seen),
      );

      expect(base64Decode(result).length, 90);
      expect(seen, [85, 70, 55]);
    });

    test('throws when even the lowest quality is too large', () async {
      final f = fileWith(List.filled(9000, 1));

      expect(
        () => prepareImageForUpload(
          f,
          maxBytes: 100,
          qualityLadder: const [85, 55],
          compressor: fakeCompressor({85: 900, 55: 800}),
        ),
        throwsA(isA<ImageTooLargeException>()),
      );
    });

    test('reports the smallest achieved size in the error', () async {
      final f = fileWith(List.filled(9000, 1));

      try {
        await prepareImageForUpload(
          f,
          maxBytes: 100,
          qualityLadder: const [85, 55],
          compressor: fakeCompressor({85: 900, 55: 800}),
        );
        fail('expected ImageTooLargeException');
      } on ImageTooLargeException catch (e) {
        expect(e.actualBytes, 800);
        expect(e.maxBytes, 100);
      }
    });

    test('falls back to the raw file when compression is unavailable',
        () async {
      // Compressor returns null, as it does when the plugin has no platform
      // implementation.
      final f = fileWith([1, 2, 3, 4, 5]);

      final result = await prepareImageForUpload(
        f,
        maxBytes: 100,
        compressor: (path,
                {required int quality, required int maxDimension}) async =>
            null,
      );

      expect(result, base64Encode([1, 2, 3, 4, 5]));
    });

    test('fallback still enforces the size limit', () async {
      final f = fileWith(List.filled(500, 9));

      expect(
        () => prepareImageForUpload(
          f,
          maxBytes: 100,
          compressor: (path,
                  {required int quality, required int maxDimension}) async =>
              null,
        ),
        throwsA(isA<ImageTooLargeException>()),
      );
    });

    test('passes the configured max dimension through', () async {
      final dims = <int>[];
      final f = fileWith(List.filled(9000, 1));

      await prepareImageForUpload(
        f,
        maxBytes: 100,
        maxDimension: 720,
        qualityLadder: const [85],
        compressor: fakeCompressor({85: 50}, seenDimensions: dims),
      );

      expect(dims, [720]);
    });

    test('throws when the file does not exist', () async {
      final missing = File('${tmp.path}${Platform.pathSeparator}gone.jpg');
      expect(
        () => prepareImageForUpload(missing),
        throwsA(isA<ImageUnreadableException>()),
      );
    });
  });

  group('prepareOptionalImageForUpload', () {
    test('returns null for a null file', () async {
      expect(await prepareOptionalImageForUpload(null), isNull);
    });
  });

  group('defaults', () {
    test('quality ladder descends', () {
      for (var i = 1; i < kQualityLadder.length; i++) {
        expect(kQualityLadder[i], lessThan(kQualityLadder[i - 1]));
      }
    });

    test('max dimension keeps enough detail for face/document matching', () {
      expect(kMaxImageDimension, greaterThanOrEqualTo(1024));
    });
  });
}
