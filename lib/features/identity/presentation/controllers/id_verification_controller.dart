import 'package:flutter_riverpod/legacy.dart'; // keep existing
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/constants/id_type.dart';
import 'package:kudipay/core/providers/core_providers.dart'; // ← use this
import 'package:kudipay/model/IDdocument/id_verification_state.dart';
import 'package:kudipay/presentation/Identity/verification_status.dart';
// Remove the dio_provider.dart import entirely

final idVerificationProvider =
    StateNotifierProvider<IdVerificationController, IdVerificationState>(
  (ref) => IdVerificationController(ref.read(dioClientProvider)),
);

class IdVerificationController extends StateNotifier<IdVerificationState> {
  final DioClient _client;

  IdVerificationController(this._client)
      : super(const IdVerificationState(idType: IdType.bvn));

  void changeIdType(IdType type) {
    state = state.copyWith(
      idType: type,
      status: VerificationStatus.input,
      error: null,
      data: null,
    );
  }

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
      final response = await _client.post<Map<String, dynamic>>(
        '/kyc/verify-identity',
        data: {
          'id_number': idNumber,
          'id_type': state.idType.label,
        },
      );

      final data = response.data!;
      state = state.copyWith(
        status: VerificationStatus.success,
        data: {
          'name':
              data['full_name'] ?? '${data['first_name']} ${data['last_name']}',
          'first_name': data['first_name'] ?? '',
          'last_name': data['last_name'] ?? '',
          'date_of_birth': data['date_of_birth'] ?? data['dateOfBirth'] ?? '',
          'idType': state.idType.label,
        },
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  void reset() {
    state = IdVerificationState(idType: state.idType);
  }
}
