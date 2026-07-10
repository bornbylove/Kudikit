import 'package:kudipay/core/constants/id_type.dart';
import 'package:kudipay/features/identity/presentation/pages/verification_status.dart';

class IdVerificationState {
  final IdType idType;
  final VerificationStatus status;
  final String? error;
  final Map<String, dynamic>? data;

  const IdVerificationState({
    required this.idType,
    this.status = VerificationStatus.idle,
    this.error,
    this.data,
  });

  IdVerificationState copyWith({
    IdType? idType,
    VerificationStatus? status,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return IdVerificationState(
      idType: idType ?? this.idType,
      status: status ?? this.status,
      error: error,
      data: data ?? this.data,
    );
  }
}
