import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:kudipay/presentation/notification/notification_preferences.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  final String baseUrl;
  final String? authToken;
  final StorageService _storageService;

  NotificationPreferencesService({
    required this.baseUrl,
    required this.authToken,
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService();

  /// Fetch notification preferences.
  /// Returns data from [MockNotificationData] during development.
  /// Replace the mock block with the real HTTP call when the backend is ready.
  Future<NotificationPreferences> fetchPreferences() async {
    // ── Mock implementation ───────────────────────────────────────────────────
    // await Future.delayed(const Duration(milliseconds: 400));
    // return NotificationPreferences.fromJson(
    //   MockNotificationData.preferencesResponse['preferences']
    //       as Map<String, dynamic>,
    // );

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationPreferences.fromJson(data['preferences']);
      } else {
        throw Exception('Failed to load notification preferences');
      }
    } catch (e) {
      return NotificationPreferences();
    }
  }

  /// Update notification preferences on server
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    // ── Mock implementation ───────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 300));
    // Persist locally so toggles survive a hot-restart during development.
    // await savePreferencesLocally(preferences);
    // return MockNotificationData.updatePreferencesSuccess['success'] as bool;

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'preferences': preferences.toJson()}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }

  /// Update a single notification preference
  Future<bool> updateSinglePreference(String key, bool value) async {
    // ── Mock implementation ───────────────────────────────────────────────────
    // await Future.delayed(const Duration(milliseconds: 200));
    // return true;

    // ── Real implementation ───────────────────────────────────────────────────
    try {
      final token = await _storageService.getAuthToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/preferences/$key'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'value': value}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating preference: $e');
      return false;
    }
  }

  /// Save preferences locally using SharedPreferences
  Future<void> savePreferencesLocally(
      NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_preferences',
        json.encode(preferences.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving preferences locally: $e');
    }
  }

  /// Load preferences from local storage
  Future<NotificationPreferences> loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('notification_preferences');
      if (data != null) {
        return NotificationPreferences.fromJson(json.decode(data));
      }
    } catch (e) {
      debugPrint('Error loading local preferences: $e');
    }
    return NotificationPreferences();
  }
}
