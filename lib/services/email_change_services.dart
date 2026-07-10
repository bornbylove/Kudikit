import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kudipay/model/device/device_metadata.dart';
import 'package:kudipay/services/device_info_services.dart';
import 'package:kudipay/services/storage_services.dart';

class EmailChangeService {
  final String baseUrl;
  final String? authToken;
  final StorageService _storageService;

  EmailChangeService({
    required this.baseUrl,
    required this.authToken,
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService();

  /// Request OTP for email change.
  /// UPDATED: Collects DeviceMetadata so the backend can populate the
  /// security email template (Image 1) — changing your email is a
  /// sensitive account action that warrants device/IP/location context.
  Future<Map<String, dynamic>> requestOTP(String currentEmail) async {
    // Collect device metadata concurrently with the simulated delay.
    final metaFuture = DeviceInfoService.collect();
    await Future.delayed(const Duration(seconds: 1));
    final DeviceMetadata meta = await metaFuture;

    // ── Mock implementation ───────────────────────────────────────────────────
    // return MockEmailChangeData.requestOtpSuccess(
    //   email: maskEmail(currentEmail),
    //   deviceMetadata: meta,   // NEW — mock now receives metadata
    // );

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final body = meta.mergeInto({'email': currentEmail});
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/email/request-otp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'maskedEmail': data['maskedEmail']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    // ── Mock implementation ───────────────────────────────────────────────────
    await Future.delayed(const Duration(seconds: 1));
    // return MockEmailChangeData.verifyOtpSuccess;

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/email/verify-otp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'otp': otp}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified successfully',
          'verificationToken': data['verificationToken']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Change email address
  Future<Map<String, dynamic>> changeEmail({
    required String newEmail,
    required String verificationToken,
  }) async {
    // ── Mock implementation ───────────────────────────────────────────────────
    await Future.delayed(const Duration(seconds: 1));
    // return MockEmailChangeData.changeEmailSuccess(newEmail: newEmail);

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/email/change'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(
            {'newEmail': newEmail, 'verificationToken': verificationToken}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email changed successfully',
          'newEmail': data['newEmail']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change email'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Resend OTP — also attaches device metadata so the backend re-sends
  /// the full security email template on resend.
  Future<Map<String, dynamic>> resendOTP() async {
    final metaFuture = DeviceInfoService.collect();
    await Future.delayed(const Duration(seconds: 1));
    final DeviceMetadata meta = await metaFuture;

    // ── Mock implementation ───────────────────────────────────────────────────
    // return MockEmailChangeData.requestOtpSuccess(deviceMetadata: meta);

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final body = meta.mergeInto({});
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/email/resend-otp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP resent successfully'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to resend OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get current user email — reads from StorageService in mock mode
  Future<String?> getCurrentEmail() async {
    try {
      final user = await _storageService.getUserModel();
      return user?.email;
    } catch (e) {
      debugPrint('Error getting current email: $e');
    }
    return null;
  }

  /// Mask email for display (e.g., a****@gmail.com)
  String maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) return '${username[0]}***@$domain';
    final visibleStart = username[0];
    final maskedPart = '*' * (username.length - 1);
    return '$visibleStart$maskedPart@$domain';
  }
}
