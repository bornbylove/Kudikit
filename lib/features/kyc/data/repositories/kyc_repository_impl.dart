// lib/features/kyc/data/repositories/kyc_repository_impl.dart

import 'dart:io';
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/core/utils/image_encoding.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_request_builders.dart';
import 'package:kudipay/features/kyc/data/repositories/kyc_status_mapper.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

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

    // Downscales and re-encodes before base64, then throws
    // ImageTooLargeException / ImageUnreadableException before the request is
    // attempted — so a problem photo surfaces as a clear error rather than a
    // send timeout.
    final selfieBase64 = await prepareImageForUpload(selfieImage);

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
  Future<KycStatusEntity> submitAddress(
    AddressEntity address, {
    required File utilityBill,
  }) async {
    final billBase64 = await prepareImageForUpload(utilityBill);

    final res = await _client.post<Map<String, dynamic>>(
      kVerifyAddressPath,
      data: buildVerifyAddressBody(
        houseNumber: address.houseNumber ?? '',
        street: address.streetName ?? '',
        lga: address.lga ?? '',
        city: address.city ?? '',
        state: address.state ?? '',
        utilityBillImageBase64: billBase64,
        landmark: address.landmark,
        area: address.area,
      ),
    );

    return kycStatusFromResponse(res.data ?? const {});
  }

  @override
  Future<KycStatusEntity> uploadDocument({
    required File frontImage,
    File? backImage,
    required DocumentType documentType,
  }) async {
    final wire = idDocumentTypeWire(documentType);
    if (wire == null) {
      throw ArgumentError.value(
        documentType,
        'documentType',
        'is not a government ID — a utility bill is proof of address and '
            'must be submitted via submitAddress()',
      );
    }

    final frontBase64 = await prepareImageForUpload(frontImage);
    final backBase64 = await prepareOptionalImageForUpload(backImage);

    final res = await _client.post<Map<String, dynamic>>(
      kVerifyIdDocumentPath,
      data: buildVerifyIdDocumentBody(
        documentTypeWire: wire,
        frontImageBase64: frontBase64,
        backImageBase64: backBase64,
      ),
    );

    return kycStatusFromResponse(res.data ?? const {});
  }
}
