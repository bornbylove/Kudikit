// test/image_base64_util_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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
}
