// lib/services/profile_services.dart
// Fixes a routing bug in the old AuthService.getProfile()/updateProfile():
// those called '/profile' and '/profile/update-profile' through
// authDioClientProvider (host :8090 — kudikit_auth_service), but neither
// route exists in that service's own OpenAPI spec. Both are confirmed live
// on the security/core service instead (199.192.22.72:8181/v3/api-docs —
// same host already proven working for /security/* and /dashboard).
//
//   GET  /profile                 → ProfileResponseDTO{ profile, account,
//                                    verification, completenessScore,
//                                    missingFields }
//   POST /profile/update-profile  { firstName?, lastName?, email?,
//                                    dateOfBirth?, gender? }
//                                  → same ProfileResponseDTO shape
//
// The old updateProfile() also had a second, independent bug: it checked
// `data['user']` on the response, but the real ProfileResponseDTO has no
// `user` key at all (it's `profile`/`account`/`verification`) — so even
// with the host fixed, it would have silently fallen through to the
// optimistic local guess every time. Fixed here by mapping the real
// `profile` section.

import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/storage_services.dart';

class ProfileService {
  final DioClient _client;
  final StorageService _storage;
  ProfileService(this._client, this._storage);

  /// Raw `data` map (profile/account/verification/completenessScore/
  /// missingFields) — deliberately un-modeled so callers can pick exactly
  /// the fields they render, matching the original design intent.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/profile');
      final envelope = response.data ?? <String, dynamic>{};
      final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
      return data;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to load profile: ${e.toString()}');
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? bvn,
    String? nin,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
  }) async {
    final existing = await _storage.getUserModel();
    if (existing == null) throw KudiApiException('No user session found.');

    try {
      final body = <String, dynamic>{
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/profile/update-profile',
        data: body,
      );

      final envelope = response.data ?? <String, dynamic>{};
      final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
      final profile = data['profile'] as Map<String, dynamic>?;

      if (profile != null) {
        final serverFirst = profile['firstName'] as String?;
        final serverLast = profile['lastName'] as String?;
        final serverName = profile['fullName'] as String? ??
            ((serverFirst != null || serverLast != null)
                ? '${serverFirst ?? ''} ${serverLast ?? ''}'.trim()
                : null);
        return existing.copyWith(
          name: serverName ?? existing.name,
          email: profile['email'] as String? ?? existing.email,
          isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
          isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
          isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
          isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
          bvn: bvn ?? existing.bvn,
          nin: nin ?? existing.nin,
        );
      }

      // Optimistic fallback if the server didn't return a profile object.
      return existing.copyWith(
        name: (firstName != null && lastName != null)
            ? '$firstName $lastName'
            : existing.name,
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    } catch (e) {
      // Same non-blocking fallback the old implementation used — a
      // transient network error must not block the KYC/profile UI.
      return existing.copyWith(
        name: (firstName != null && lastName != null)
            ? '$firstName $lastName'
            : existing.name,
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    }
  }
}
