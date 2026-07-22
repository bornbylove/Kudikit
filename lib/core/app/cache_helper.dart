// lib/core/app/cache_helper.dart
// ─────────────────────────────────────────────────────────────────────────────
// Thin convenience wrapper over SharedPreferences for NON-sensitive values.
//
// This is intentionally minimal — StorageService
// (lib/services/storage_services.dart) remains the source of truth for all
// sensitive data (tokens, passcodes, user profile). Use CacheHelper only for
// simple, non-sensitive flags/values where a full service is overkill.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight static helper around [SharedPreferences].
class CacheHelper {
  const CacheHelper._();

  static SharedPreferences? _prefs;

  /// Must be awaited once (e.g. in main()) before the sync getters are used.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  static String? getString(String key) => _prefs?.getString(key);

  static Future<bool> setBool(String key, bool value) async {
    await init();
    return _prefs!.setBool(key, value);
  }

  static bool? getBool(String key) => _prefs?.getBool(key);

  static Future<bool> remove(String key) async {
    await init();
    return _prefs!.remove(key);
  }
}
