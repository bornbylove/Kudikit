// lib/services/security_services.dart
// Client for kudikit's security-service (confirmed live at
// 199.192.22.72:8181/v3/api-docs — see ApiConfig.securityBaseUrl):
//
//   POST   /security/biometric/enable        { type }  — records that this
//                                                         user has biometric
//                                                         login on
//   POST   /security/biometric/disable                 — no body
//   GET    /security/settings                          — data.preferences.
//                                                         sessionTimeout (s),
//                                                         data.sessions.{
//                                                         maxSessions,
//                                                         currentSession}
//   GET    /security/sessions                          — data.sessions[]
//                                                         (SessionDetail —
//                                                         NOTE different
//                                                         field names than
//                                                         the SessionDetails
//                                                         nested above)
//   DELETE /security/sessions/{sessionId}               — revoke one
//   DELETE /security/sessions/revoke-all                — revoke every
//                                                         session but this
//                                                         device's (PRD
//                                                         §2.3.2.9 "Active
//                                                         Sessions: View and
//                                                         revoke")
//
// This never sends any biometric data — the `type` field is just a label
// ("FACE"/"FINGERPRINT") the server stores for display in Settings.

import 'package:kudipay/config/dio_client.dart';

class SecuritySettings {
  final int sessionTimeoutSeconds;
  final int maxSessions;
  final bool hasBiometric;
  final String? currentDevice;
  final DateTime? lastActive;

  const SecuritySettings({
    required this.sessionTimeoutSeconds,
    required this.maxSessions,
    required this.hasBiometric,
    this.currentDevice,
    this.lastActive,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'] as Map<String, dynamic>?;
    final sessions = json['sessions'] as Map<String, dynamic>?;
    final authentication = json['authentication'] as Map<String, dynamic>?;
    // SessionDetails (nested here) uses device/lastActive — NOT the same
    // field names as SessionDetail from GET /security/sessions below.
    final currentSession = sessions?['currentSession'] as Map<String, dynamic>?;
    return SecuritySettings(
      sessionTimeoutSeconds: (preferences?['sessionTimeout'] as num?)?.toInt() ?? 0,
      maxSessions: (sessions?['maxSessions'] as num?)?.toInt() ?? 2,
      hasBiometric: authentication?['hasBiometric'] as bool? ?? false,
      currentDevice: currentSession?['device'] as String?,
      lastActive: DateTime.tryParse(currentSession?['lastActive'] as String? ?? ''),
    );
  }
}

class ActiveSession {
  final String sessionId;
  final String deviceInfo;
  final String ipAddress;
  final DateTime? lastActivity;
  final DateTime? createdAt;

  const ActiveSession({
    required this.sessionId,
    required this.deviceInfo,
    required this.ipAddress,
    this.lastActivity,
    this.createdAt,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      sessionId: json['sessionId'] as String? ?? '',
      deviceInfo: json['deviceInfo'] as String? ?? 'Unknown device',
      ipAddress: json['ipAddress'] as String? ?? '',
      lastActivity: DateTime.tryParse(json['lastActivity'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class SecurityService {
  final DioClient _client;
  SecurityService(this._client);

  Future<void> enableBiometric(String type) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/security/biometric/enable',
        data: {'type': type},
      );
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to enable biometric login: $e');
    }
  }

  Future<void> disableBiometric() async {
    try {
      await _client.post<Map<String, dynamic>>('/security/biometric/disable');
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to disable biometric login: $e');
    }
  }

  /// POST /security/pin/create — first-time transaction PIN. The backend is
  /// the source of truth (rejects duplicates, weak PINs, non-4-digit input)
  /// — kudikit_auth_service equivalent doesn't exist; this is the ONLY place
  /// the PIN a user sets during onboarding gets recorded server-side. Throws
  /// KudiApiException with the server's real message (e.g. "PIN is too
  /// weak.") on rejection — surface `.message` directly, don't reword it.
  Future<void> createTransactionPin({
    required String pin,
    required String confirmPin,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/security/pin/create',
        data: {'pin': pin, 'confirmPin': confirmPin},
      );
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to create transaction PIN: $e');
    }
  }

  /// Returns null on any failure (offline, server error) — callers fall
  /// back to the PRD's static per-tier timeout rather than blocking on this.
  Future<SecuritySettings?> getSecuritySettings() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/security/settings');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return SecuritySettings.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<ActiveSession>> getSessions() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/security/sessions');
      final data = response.data?['data'] as Map<String, dynamic>?;
      final sessions = data?['sessions'] as List<dynamic>? ?? [];
      return sessions
          .map((s) => ActiveSession.fromJson(s as Map<String, dynamic>))
          .toList();
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to load active sessions: $e');
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      await _client.delete<Map<String, dynamic>>('/security/sessions/$sessionId');
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to revoke session: $e');
    }
  }

  Future<void> revokeAllOtherSessions() async {
    try {
      await _client.delete<Map<String, dynamic>>('/security/sessions/revoke-all');
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to revoke sessions: $e');
    }
  }
}
