// lib/features/kyc/data/repositories/kyc_repository_impl.dart

import 'dart:io';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/core/utils/image_encoding.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_request_builders.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_status_mapper.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

import 'package:dio/dio.dart';
import 'package:kudipay/features/kyc/domain/repositories/kyc_repositories.dart';
import 'package:kudipay/features/identity/domain/entities/document_data.dart';

class KycRepositoryImpl implements KycRepository {
  final DioClient _client;
  const KycRepositoryImpl(this._client);

  // ── KycRepository ──────────────────────────────────────────────────────────

  @override
  Future<KycStatusEntity> getKycStatus() async {
    final res = await _client.get<Map<String, dynamic>>('/auth/kyc/status');
    return kycStatusFromResponse(res.data ?? const {});
  }

  @override
  Future<KycStatusEntity> verifyIdentity({
    required String idNumber,
    required IdType idType,
    required File selfieImage,
  }) async {
    if (idNumber.length != 11) {
      throw Exception('${idType.label} must be exactly 11 digits.');
    }

    // Throws ImageTooLargeException / ImageUnreadableException before the
    // request is attempted, so an oversized photo surfaces as a clear error
    // rather than a send timeout.
    final selfieBase64 = await encodeImageFile(selfieImage);

    final res = await _client.post<Map<String, dynamic>>(
      kycVerifyPathFor(idType),
      data: buildIdentityVerificationBody(
        idNumber: idNumber,
        idType: idType,
        selfieImageBase64: selfieBase64,
      ),
    );

    // Both endpoints return ApiResponseKycVerification — the same payload as
    // GET /auth/kyc/status — so the response is the refreshed KYC state.
    return kycStatusFromResponse(res.data ?? const {});
  }

  @override
  Future<void> submitAddress(AddressEntity address) async {
    await _client.post<void>(
      '/kyc/address',
      data: {
        'state': address.state,
        'city': address.city,
        'lga': address.lga,
        'landmark': address.landmark,
        'street_name': address.streetName,
        'house_number': address.houseNumber,
      },
    );
  }

  @override
  Future<void> uploadDocument({
    required File file,
    required DocumentType documentType,
  }) async {
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'document_type': documentType.name,
    });

    await _client.post<void>('/kyc/document', data: formData);
  }
}
