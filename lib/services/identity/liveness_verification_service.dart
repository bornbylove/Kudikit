// lib/services/identity/liveness_verification_service.dart
//
// Domain/repository layer for liveness verification — the one thing the
// Riverpod state layer talks to. Hides both the base64-encoding step and
// the Dojah transport client from callers, so LivenessNotifier only ever
// deals in "here's a captured selfie" / "here's a result or a
// DojahException", never in HTTP or encoding details.
//
// Sibling services for BVN/NIN (see identity_verification_type.dart) would
// live in this same directory, each composing its own transport client the
// same way this one composes DojahClient — no shared base class needed
// until a second implementation actually exists.

import 'package:image_picker/image_picker.dart' show XFile;

import 'package:kudipay/core/utils/image_base64_util.dart';
import 'package:kudipay/model/identity/liveness_response.dart';
import 'package:kudipay/services/identity/dojah_client.dart';

class LivenessVerificationService {
  final DojahClient _client;

  LivenessVerificationService(this._client);

  /// Encodes [selfie] and runs it through Dojah's liveness check. The
  /// base64 payload built here is local to this call and is not retained
  /// once it returns — only the parsed [LivenessResponse] (and, at the
  /// caller's discretion, the original image file path) survives past it.
  Future<LivenessResponse> verify(XFile selfie) async {
    final base64Image = await ImageBase64Util.encodeToBase64(selfie);
    return _client.checkLiveness(base64Image);
  }
}
