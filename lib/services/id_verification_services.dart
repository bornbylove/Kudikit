// lib/services/id_verification_services.dart

import 'package:kudipay/config/dio_client.dart';

enum IdentificationType {
  BVN,
  NIN;

  String get apiValue => name;
  String get displayLabel => name;
}

class UserVerificationData {
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String? photoUrl;
  final String gender;
  final String idNumber;
  final String idType;

  const UserVerificationData({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.photoUrl,
    required this.gender,
    required this.idNumber,
    required this.idType,
  });

  factory UserVerificationData.fromJson(Map<String, dynamic> json) {
    return UserVerificationData(
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      middleName: json['middle_name'] ?? json['middleName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      fullName: json['full_name'] ??
          json['fullName'] ??
          '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
      dateOfBirth: DateTime.parse(json['date_of_birth'] ?? json['dateOfBirth']),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      gender: json['gender'] ?? '',
      idNumber: json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
      idType: json['id_type'] ?? json['idType'] ?? 'BVN',
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'full_name': fullName,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'gender': gender,
        'id_number': idNumber,
        'id_type': idType,
      };
}

class VerificationException implements Exception {
  final String message;
  final int? statusCode;

  const VerificationException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class IdentityVerificationService {
  final DioClient _client;

  const IdentityVerificationService(this._client);

  /// Detects whether the input is a BVN or NIN.
  /// BVN starts with '2'; NIN uses other patterns.
  IdentificationType detectIdType(String input) {
    if (input.length != 11) {
      throw const VerificationException(
          'Invalid ID length. Must be 11 digits.');
    }
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      throw const VerificationException('ID must contain only digits.');
    }
    return input.startsWith('2')
        ? IdentificationType.BVN
        : IdentificationType.NIN;
  }

  /// Verifies identity using BVN or NIN.
  /// Auto-detects the ID type if not provided.
  /// POST /kyc/verify-identity — { id_number, id_type }
  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    String? idType,
  }) async {
    final detectedType = idType ?? detectIdType(idNumber).apiValue;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/kyc/verify-identity',
        data: {
          'id_number': idNumber,
          'id_type': detectedType,
        },
      );
      return UserVerificationData.fromJson(response.data!);
    } on KudiApiException catch (e) {
      throw VerificationException(e.message, e.statusCode);
    } catch (e) {
      throw VerificationException('Verification error: ${e.toString()}');
    }
  }
}
