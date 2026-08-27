import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/constant/id_type.dart';
import 'package:kudipay/core/utils/image_base64_util.dart';
import 'package:kudipay/model/IDdocument/id_verification_state.dart';
import 'package:kudipay/presentation/Identity/verification_status.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/identity/liveness_provider.dart';

final idVerificationProvider =
    StateNotifierProvider<IdVerificationController, IdVerificationState>(
  (ref) => IdVerificationController(ref),
);

class IdVerificationController extends StateNotifier<IdVerificationState> {
  final Ref _ref;

  IdVerificationController(this._ref)
      : super(const IdVerificationState(idType: IdType.bvn));

  void changeIdType(IdType type) {
    state = state.copyWith(
      idType: type,
      status: VerificationStatus.input,
      error: null,
      data: null,
    );
  }

  /// Slice 5: submits the entered number to the real auth-service
  /// (POST /auth/kyc/verify-bvn or /verify-nin depending on the selected
  /// type), attaching the selfie retained in [LivenessState.imagePath].
  /// On success the authoritative summary is persisted via AuthNotifier; the
  /// registry identity details are exposed for the confirm step.
  Future<void> verifyId(String idNumber) async {
    if (idNumber.length != 11) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: '${state.idType.label} must be 11 digits',
      );
      return;
    }

    state = state.copyWith(
      status: VerificationStatus.loading,
      error: null,
    );

    try {
      // The selfie file path survives in provider memory through to this
      // step — re-encode it for submission (no new selfie storage).
      final imagePath = _ref.read(livenessProvider).imagePath;
      if (imagePath == null || imagePath.isEmpty) {
        state = state.copyWith(
          status: VerificationStatus.error,
          error: 'Please complete selfie verification first.',
        );
        return;
      }
      final selfieImageBase64 =
          await ImageBase64Util.encodeToBase64(XFile(imagePath));

      final authNotifier = _ref.read(authProvider.notifier);
      final isBvn = state.idType == IdType.bvn;
      final summary = isBvn
          ? await authNotifier.verifyBvn(
              bvn: idNumber, selfieImageBase64: selfieImageBase64)
          : await authNotifier.verifyNin(
              nin: idNumber, selfieImageBase64: selfieImageBase64);

      final verified = isBvn ? summary.bvnVerified : summary.ninVerified;
      // 200 MANUAL_REVIEW (e.g. provider unavailable) must NOT be presented as
      // a verified identity — reuse the existing error-banner UX.
      if (!verified || summary.requiresManualReview) {
        state = state.copyWith(
          status: VerificationStatus.error,
          error: summary.requiresManualReview
              ? 'Your verification is pending manual review. Please try again later.'
              : 'We could not verify your identity. Please try again.',
        );
        return;
      }

      state = state.copyWith(
        status: VerificationStatus.success,
        data: {
          'name': summary.fullName ?? '',
          'fullName': summary.fullName ?? '',
          'dateOfBirth': summary.dateOfBirth ?? '',
          'idType': state.idType.label,
        },
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() {
    state = IdVerificationState(idType: state.idType);
  }
}