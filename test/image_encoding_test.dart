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
}
