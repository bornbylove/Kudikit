import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';

// ============================================================================
// StorageService
// ----------------------------------------------------------------------------
// This class handles ALL data persistence for the app.
//
// There are two types of storage used here:
//
//   1. FlutterSecureStorage  → for SENSITIVE data (tokens, passcodes)
//      - Data is encrypted on the device.
//      - On Android: uses EncryptedSharedPreferences.
//      - On iOS: uses the Keychain.
//
//   2. SharedPreferences     → for NON-SENSITIVE data (user profile, settings)
//      - Data is stored as plain key-value pairs.
//      - Never store passwords or tokens here!
//
// This class uses the SINGLETON pattern, meaning only one instance of it
// ever exists in your app. You access it via StorageService.instance.
// ============================================================================

class StorageService {
  // ---------------------------------------------------------------------------
  // SINGLETON SETUP
  // ---------------------------------------------------------------------------
  // Private constructor — prevents anyone from calling `StorageService()`
  // directly from outside this class.
  StorageService._privateConstructor();

  // The single, shared instance of this class.
  static final StorageService _instance = StorageService._privateConstructor();

  // Public getter to access the instance: `StorageService.instance`
  static StorageService get instance => _instance;

  // Factory constructor so `StorageService()` also returns the same instance.
  factory StorageService() => _instance;

  // ---------------------------------------------------------------------------
  // STORAGE INSTANCES
  // ---------------------------------------------------------------------------

  // Secure, encrypted storage for sensitive data.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Uses Android Keystore encryption
    ),
    iOptions: IOSOptions(
      accessibility:
          KeychainAccessibility.first_unlock, // Available after first unlock
    ),
  );

  // ---------------------------------------------------------------------------
  // STORAGE KEYS
  // ---------------------------------------------------------------------------
  // These are the "labels" under which data is saved.
  // Using constants prevents typos across the codebase.

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userPasscodeKey =
      'user_passcode'; // renamed from _userPinKey for clarity
  static const String _biometricKey = 'biometric_enabled';
  static const String _userInfoKey = 'user_info';
  static const String _userModelKey = 'user_model';
  static const String _isAuthKey = 'is_authenticated';
  static const String _lastLoginKey = 'last_login';
  static const String _currentTierKey = 'current_tier';
  static const String _lastTierUpgradeKey = 'last_tier_upgrade';
  static const String _completedRequirementsKey = 'completed_requirements';

  // ===========================================================================
  // AUTH TOKEN
  // ===========================================================================
  // The auth token is a string your server gives the user after login.
  // It proves the user is logged in without needing to send their password
  // on every request. It must be stored securely.

  /// Saves the authentication token securely and marks the user as authenticated.
  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _authTokenKey, value: token);
      await _setAuthenticated(true);
    } catch (e) {
      throw StorageException('Failed to save auth token: $e');
    }
  }

  /// Retrieves the stored authentication token, or null if none exists.
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _authTokenKey);
    } catch (e) {
      return null; // Fail silently — caller handles missing token
    }
  }

  /// Saves the refresh token securely.
  /// Refresh tokens are used to get a new auth token when the current one expires.
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw StorageException('Failed to save refresh token: $e');
    }
  }

  /// Retrieves the stored refresh token, or null if none exists.
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Returns true if a non-empty auth token is stored.
  Future<bool> hasValidToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ===========================================================================
  // PASSCODE (Stored as a secure hash — NEVER as plain text!)
  // ===========================================================================
  //
  // IMPORTANT CONCEPT — Why do we hash the passcode?
  //
  // We NEVER store the actual passcode. Instead we store a "hash" of it.
  // A hash is a one-way transformation: given "MyPass1!" you always get the
  // same hash output, but you cannot reverse the hash back to "MyPass1!".
  //
  // To verify a passcode later, we hash what the user typed and compare
  // it to the stored hash. If they match → correct passcode.
  //
  // We also add a "salt" — a random string mixed in before hashing.
  // This means even if two users have the same passcode, their stored
  // hashes will be different.
  //
  // Format stored in secure storage: "salt:hash:iterations"
  //   - salt       → random bytes (base64 encoded)
  //   - hash       → PBKDF2 hash of (passcode + salt)
  //   - iterations → how many times the hash was repeated (makes brute-force harder)
  //
  // ===========================================================================

  /// Generates a random 16-byte salt, returned as a base64 string.
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a passcode using a simplified PBKDF2-style algorithm with HMAC-SHA256.
  ///
  /// [passcode]   → the plain-text passcode to hash
  /// [salt]       → base64-encoded salt string
  /// [iterations] → number of hashing rounds (higher = more secure but slower)
  ///
  /// Returns a base64-encoded hash string.
  String _hashPasscode(String passcode, String salt, {int iterations = 10000}) {
    final saltBytes = base64Decode(salt);
    final passcodeBytes = utf8.encode(passcode);

    var result = Uint8List.fromList(passcodeBytes);
    for (var i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, saltBytes);
      final combined = Uint8List.fromList([...result, ...passcodeBytes]);
      result = Uint8List.fromList(hmac.convert(combined).bytes);
    }

    return base64Encode(result);
  }

  /// Validates that a passcode meets the required complexity rules.
  /// Throws a [StorageException] if any rule is violated.
  ///
  /// Rules (must match your SignUpScreen validator):
  ///   - 8 to 12 characters long
  ///   - At least one uppercase letter
  ///   - At least one lowercase letter
  ///   - At least one number
  ///   - At least one special character: ! @ # $ % ^ & *
  void _validatePasscode(String passcode) {
    if (passcode.isEmpty || passcode.length < 8 || passcode.length > 12) {
      throw StorageException('Passcode must be 8–12 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(passcode)) {
      throw StorageException(
          'Passcode must contain at least one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(passcode)) {
      throw StorageException(
          'Passcode must contain at least one lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(passcode)) {
      throw StorageException('Passcode must contain at least one number');
    }
    if (!RegExp(r'[!@#$%^&*]').hasMatch(passcode)) {
      throw StorageException(
          'Passcode must contain at least one special character (!@#\$%^&*)');
    }
  }

  /// Saves the user's passcode securely.
  ///
  /// Steps:
  ///   1. Validate the passcode meets complexity rules.
  ///   2. Generate a random salt.
  ///   3. Hash the passcode with the salt.
  ///   4. Store "salt:hash:iterations" in encrypted storage.
  Future<void> savePasscode(String passcode) async {
    try {
      _validatePasscode(passcode); // Step 1 — throws if invalid

      final salt = _generateSalt(); // Step 2
      const iterations = 10000;
      final hash = _hashPasscode(
        // Step 3
        passcode,
        salt,
        iterations: iterations,
      );

      final storedValue = '$salt:$hash:$iterations'; // Step 4
      await _secureStorage.write(key: _userPasscodeKey, value: storedValue);
    } catch (e) {
      // Re-throw as StorageException so callers get a consistent error type.
      // But avoid double-wrapping if it's already a StorageException.
      if (e is StorageException) rethrow;
      throw StorageException('Failed to save passcode: $e');
    }
  }

  // Keep savePin as an alias so existing call sites (auth_provider.dart) don't break.
  Future<void> savePin(String pin) => savePasscode(pin);

  /// Reads and parses the stored passcode hash data.
  /// Returns null if no passcode is stored or the format is invalid.
  Future<Map<String, dynamic>?> _getStoredPasscodeData() async {
    try {
      final storedValue = await _secureStorage.read(key: _userPasscodeKey);
      if (storedValue == null) return null;

      final parts = storedValue.split(':');
      if (parts.length != 3) {
        // Stored value is in an unexpected format — treat as missing.
        return null;
      }

      return {
        'salt': parts[0],
        'hash': parts[1],
        'iterations': int.parse(parts[2]),
      };
    } catch (e) {
      return null;
    }
  }

  /// Verifies an entered passcode against the stored hash.
  ///
  /// Returns true if the passcode matches, false otherwise.
  /// Uses constant-time comparison to prevent timing attacks.
  Future<bool> verifyPasscode(String enteredPasscode) async {
    try {
      final data = await _getStoredPasscodeData();
      if (data == null) return false;

      final salt = data['salt'] as String;
      final storedHash = data['hash'] as String;
      final iterations = data['iterations'] as int;

      final enteredHash =
          _hashPasscode(enteredPasscode, salt, iterations: iterations);

      return _constantTimeCompare(storedHash, enteredHash);
    } catch (e) {
      return false;
    }
  }

  // Keep verifyPin as an alias for backwards compatibility.
  Future<bool> verifyPin(String pin) => verifyPasscode(pin);

  /// Compares two strings in constant time to prevent timing attacks.
  ///
  /// A normal `a == b` comparison can be faster when strings differ early,
  /// which could theoretically leak information. This method always takes
  /// the same amount of time regardless of where strings differ.
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Returns true if a passcode has been saved.
  Future<bool> hasPasscode() async {
    final data = await _getStoredPasscodeData();
    return data != null;
  }

  // Keep hasPin as an alias.
  Future<bool> hasPin() => hasPasscode();

  /// Deletes the stored passcode.
  Future<void> deletePasscode() async {
    await _secureStorage.delete(key: _userPasscodeKey);
  }

  // Keep deletePin as an alias.
  Future<void> deletePin() => deletePasscode();

  /// Changes the passcode after verifying the old one.
  ///
  /// Returns true if successful, false if the old passcode was wrong.
  Future<bool> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) async {
    try {
      final isValid = await verifyPasscode(oldPasscode);
      if (!isValid) return false;

      await savePasscode(newPasscode);
      return true;
    } catch (e) {
      throw StorageException('Failed to change passcode: $e');
    }
  }

  // ===========================================================================
  // USER DATA
  // ===========================================================================
  // UserInfo and UserModel are stored as JSON strings in SharedPreferences.
  // This is safe because they don't contain sensitive credentials.

  /// Saves a [UserInfo] object to SharedPreferences.
  Future<void> saveUserInfo(UserInfo userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInfoKey, jsonEncode(userInfo.toJson()));
    } catch (e) {
      throw StorageException('Failed to save user info: $e');
    }
  }

  /// Retrieves the stored [UserInfo], or null if none exists.
  Future<UserInfo?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userInfoKey);
      if (json == null) return null;
      return UserInfo.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Saves a [UserModel] object to SharedPreferences.
  Future<void> saveUserModel(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userModelKey, jsonEncode(user.toJson()));
    } catch (e) {
      throw StorageException('Failed to save user model: $e');
    }
  }

  /// Retrieves the stored [UserModel], or null if none exists.
  Future<UserModel?> getUserModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userModelKey);
      if (json == null) return null;
      return UserModel.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  Future<bool> changePin(
      {required String oldPin, required String newPin}) async {
    try {
      // Verify old PIN first
      final isValid = await verifyPin(oldPin);
      if (!isValid) return false;

      // Save new PIN
      await savePin(newPin);
      return true;
    } catch (e) {
      throw StorageException('Failed to change PIN: $e');
    }
  }

  // ===========================================================================
  // AUTHENTICATION STATE
  // ===========================================================================

  /// Marks the user as authenticated and records the login time.
  Future<void> _setAuthenticated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthKey, value);
    if (value) {
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    }
  }

  /// Returns true if the user is marked as authenticated AND has a valid token.
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_isAuthKey) ?? false;
    if (isAuth) {
      return await hasValidToken();
    }
    return false;
  }

  /// Returns the last login time, or null if never logged in.
  Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastLoginKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // ===========================================================================
  // BIOMETRIC
  // ===========================================================================

  /// Saves whether the user has enabled biometric login (fingerprint/Face ID).
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricKey, value: enabled.toString());
  }

  /// Returns true if biometric login is enabled.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricKey);
    return value == 'true';
  }

  // ===========================================================================
  // LOGOUT / CLEAR
  // ===========================================================================

  /// Clears only auth-related data (token, passcode, user data).
  /// Use this on logout.
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userPasscodeKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
    await prefs.remove(_userModelKey);
    await prefs.setBool(_isAuthKey, false);
  }

  /// Clears ALL stored data — both secure storage and shared preferences.
  /// Use this for full reset / account deletion.
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ===========================================================================
  // TIER MANAGEMENT
  // ===========================================================================
  // "Tiers" refer to account levels (e.g. basic, standard, premium).
  // These are non-sensitive so they live in SharedPreferences.

  /// Saves the user's current tier level.
  /// Accepts either a String or a TierLevel enum.
  Future<void> saveCurrentTier(dynamic tierLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierValue = tierLevel is String
          ? tierLevel
          : tierLevel.toString().split('.').last;
      await prefs.setString(_currentTierKey, tierValue);
    } catch (e) {
      throw StorageException('Failed to save tier: $e');
    }
  }

  /// Retrieves the current tier level string, defaulting to 'basic'.
  Future<String> getCurrentTier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentTierKey) ?? 'basic';
    } catch (e) {
      return 'basic';
    }
  }

  /// Saves the date of the last tier upgrade.
  Future<void> saveLastTierUpgradeDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTierUpgradeKey, date.toIso8601String());
    } catch (e) {
      throw StorageException('Failed to save tier upgrade date: $e');
    }
  }

  /// Retrieves the last tier upgrade date, or null if never upgraded.
  Future<DateTime?> getLastTierUpgradeDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastTierUpgradeKey);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      return null;
    }
  }

  /// Saves a map of completed KYC/tier requirements.
  Future<void> saveCompletedRequirements(Map<String, bool> requirements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _completedRequirementsKey, jsonEncode(requirements));
    } catch (e) {
      throw StorageException('Failed to save completed requirements: $e');
    }
  }

  /// Retrieves the completed requirements map, or an empty map if none saved.
  Future<Map<String, bool>> getCompletedRequirements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_completedRequirementsKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      return {};
    }
  }

  /// Clears all tier-related data.
  Future<void> clearTierData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentTierKey);
      await prefs.remove(_lastTierUpgradeKey);
      await prefs.remove(_completedRequirementsKey);
    } catch (e) {
      throw StorageException('Failed to clear tier data: $e');
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Returns true the very first time the app is launched, then false after.
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('first_launch') ?? true;
    if (isFirst) await prefs.setBool('first_launch', false);
    return isFirst;
  }

  /// Saves the user's preferred theme ('light', 'dark', or 'system').
  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  /// Retrieves the user's preferred theme, defaulting to 'system'.
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'system';
  }
}

// =============================================================================
// StorageException
// -----------------------------------------------------------------------------
// A custom exception class for storage errors.
// Using a custom class (instead of throwing raw Exceptions) lets callers
// catch specifically storage errors with: catch (e) { if (e is StorageException) ... }
// =============================================================================

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
