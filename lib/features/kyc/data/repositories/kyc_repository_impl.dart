// lib/features/kyc/data/repositories/kyc_repository_impl.dart

import 'dart:io';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/features/kyc/domain/entities/kyc_entities.dart';

import 'package:dio/dio.dart';
import 'package:kudipay/features/kyc/domain/repositories/kyc_repositories.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';

class KycRepositoryImpl implements KycRepository {
  final DioClient _client;
  const KycRepositoryImpl(this._client);

  // ── Helpers ────────────────────────────────────────────────────────────────

  IdType _parseIdType(String raw) {
    switch (raw.toUpperCase()) {
      case 'NIN':
        return IdType.nin;
      default:
        return IdType.bvn;
    }
  }

  VerifiedIdentityEntity _parseIdentity(Map<String, dynamic> json) {
    final rawType = (json['id_type'] ?? json['idType'] ?? 'BVN').toString();
    return VerifiedIdentityEntity(
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      middleName: json['middle_name'] ?? json['middleName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      dateOfBirth: DateTime.parse(
          json['date_of_birth'] ?? json['dateOfBirth'] ?? '2000-01-01'),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      gender: json['gender'] ?? '',
      idNumber: json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
      idType: _parseIdType(rawType),
    );
  }

  // ── KycRepository ──────────────────────────────────────────────────────────

  @override
  Future<VerifiedIdentityEntity> verifyIdentity({
    required String idNumber,
    required IdType idType,
  }) async {
    if (idNumber.length != 11) {
      throw Exception('${idType.label} must be exactly 11 digits.');
    }

    final res = await _client.post<Map<String, dynamic>>(
      '/kyc/verify-identity',
      data: {'id_number': idNumber, 'id_type': idType.label},
    );

    return _parseIdentity(res.data!);
  }

  @override
  Future<void> confirmIdentity({
    required VerifiedIdentityEntity identity,
  }) async {
    await _client.post<void>(
      '/kyc/confirm-identity',
      data: {
        'id_number': identity.idNumber,
        'id_type': identity.idType.label,
        'first_name': identity.firstName,
        'last_name': identity.lastName,
        'date_of_birth': identity.dateOfBirth.toIso8601String(),
      },
    );
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
  Future<SelfieEntity> uploadSelfie(File imageFile) async {
    final formData = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'selfie.jpg',
      ),
    });

    await _client.post<void>('/kyc/selfie', data: formData);

    return SelfieEntity(
      imagePath: imageFile.path,
      validationPassed: true,
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
