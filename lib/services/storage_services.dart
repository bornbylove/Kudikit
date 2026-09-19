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
      accessibility: KeychainAccessibility.first_unlock, // Available after first unlock
    ),
  );

  // ---------------------------------------------------------------------------
  // STORAGE KEYS
  // ---------------------------------------------------------------------------
  // These are the "labels" under which data is saved.
  // Using constants prevents typos across the codebase.

  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userPasscodeKey = 'user_passcode'; // renamed from _userPinKey for clarity
  static const String _biometricKey = 'biometric_enabled';
  static const String _biometricCredentialKey = 'biometric_credential';
  static const String _userInfoKey = 'user_info';
  static const String _userModelKey = 'user_model';
  static const String _isAuthKey = 'is_authenticated';
  static const String _lastLoginKey = 'last_login';
  static const String _currentTierKey = 'current_tier';
  static const String _lastTierUpgradeKey = 'last_tier_upgrade';
  static const String _completedRequirementsKey = 'completed_requirements';

  // ===========================================================================
  // DEVICE IDENTITY
  // ===========================================================================
  // kudikit_auth_service's LoginRequest requires a `deviceFingerprint` (a
  // persistent per-install identifier the client generates and stores, NOT an
  // IMEI — modern mobile OSes block apps from reading those). A login from a
  // fingerprint not already trusted for the account triggers a DEVICE_LINK
  // OTP challenge instead of a session, so this must be stable across app
  // restarts and logins. It is deliberately NOT cleared by clearAuth() — the
  // identifier belongs to the device install, not to the signed-in user — but
  // IS wiped by clearAll() (full factory reset).
  //
  // Generated once as 16 cryptographically-secure random bytes hex-encoded
  // (32 chars). No extra package needed.

  /// Returns the stable per-install device fingerprint, generating and
  /// persisting it on first use.
  Future<String> getOrCreateDeviceFingerprint() async {
    try {
      final existing = await _secureStorage.read(key: _deviceFingerprintKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      final fingerprint =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _secureStorage.write(
        key: _deviceFingerprintKey,
        value: fingerprint,
      );
      return fingerprint;
    } catch (e) {
      throw StorageException('Failed to resolve device fingerprint: $e');
    }
  }

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

  /// Validates a passcode against the PRD's Passcode Security Rules
  /// (Registration Screen §8, confirmed 2026-08-10 — supersedes the
  /// 8-12-char alphanumeric rule this briefly used):
  ///
  ///   a. Length: 6-8 numeric digits only
  ///   b. Prohibited patterns:
  ///      i.   Sequential (123456, 456789)
  ///      ii.  Repetitive (111111, 222222)
  ///      iii. Phone number segments (last 6 digits of entered phone)
  ///      iv.  Common PINs (PRD: "top 10,000 from breached databases")
  ///      v.   Date patterns (DDMMYY, MMDDYY)
  ///
  /// On (b)(iv): this checks a small curated list of well-known common PINs,
  /// not a real 10,000-entry breach-frequency dataset — fabricating one
  /// would be worse than not having it. A real "top 10,000" blocklist is a
  /// genuine follow-up (arguably better maintained centrally/backend-side
  /// than baked into the app binary), not something to treat as done here.
  ///
  /// (c) bcrypt work-factor-12 hashing and (d) hashed-only storage are
  /// server-side requirements already met by kudikit_auth_service's
  /// PasscodeValidator/User credential storage — this method validates the
  /// *format* rules mobile is responsible for; the hash below this method
  /// (PBKDF2-HMAC-SHA256, 10k iterations) is this app's LOCAL passcode
  /// storage for biometric/offline-unlock convenience, a separate concern
  /// from the account's authoritative server-side credential.
  ///
  /// Mirrors lib/presentation/signup/signup.dart's `_updatePasscodeCriteria`
  /// — keep the two in sync if either changes.
  ///
  /// Throws a [StorageException] if any rule is violated.
  static const _commonPasscodes = {
    '123456', '654321', '111111', '000000', '121212', '112233', '123123',
    '696969', '123321', '111222', '102030', '789456', '147258', '159753',
    '246810', '135791', '101010', '202020', '070707', '010101', '222222',
    '333333', '444444', '555555', '666666', '777777', '888888', '999999',
  };

  void _validatePasscode(String passcode, {String? phoneNumber}) {
    if (passcode.isEmpty) {
      throw StorageException('Passcode cannot be empty');
    }
    if (!RegExp(r'^\d+$').hasMatch(passcode)) {
      throw StorageException('Passcode must contain only digits');
    }
    if (passcode.length < 6 || passcode.length > 8) {
      throw StorageException('Passcode must be 6-8 digits');
    }
    if (_isSequential(passcode)) {
      throw StorageException('Passcode cannot be a sequential pattern');
    }
    if (_isRepetitive(passcode)) {
      throw StorageException('Passcode cannot be a repetitive pattern');
    }
    if (_commonPasscodes.contains(passcode)) {
      throw StorageException('This passcode is too common, please choose another');
    }
    if (passcode.length == 6 && _isDatePattern(passcode)) {
      throw StorageException('Passcode cannot be a date (e.g. DDMMYY)');
    }
    if (phoneNumber != null && phoneNumber.length >= 6) {
      final lastSixOfPhone = phoneNumber.substring(phoneNumber.length - 6);
      if (passcode.contains(lastSixOfPhone)) {
        throw StorageException('Passcode cannot contain your phone number');
      }
    }
  }

  /// True if a 6-digit [passcode] reads as a plausible DDMMYY or MMDDYY
  /// date — simple range checks (day 01-31, month 01-12), not full
  /// calendar validation (e.g. doesn't reject "300200" for a non-existent
  /// Feb 30); that's the standard, sufficient bar for a PIN-policy check.
  bool _isDatePattern(String passcode) {
    final a = int.parse(passcode.substring(0, 2));
    final b = int.parse(passcode.substring(2, 4));
    // DDMMYY: a=day, b=month
    if (a >= 1 && a <= 31 && b >= 1 && b <= 12) return true;
    // MMDDYY: a=month, b=day
    if (a >= 1 && a <= 12 && b >= 1 && b <= 31) return true;
    return false;
  }

  bool _isSequential(String passcode) {
    var ascending = true;
    var descending = true;
    for (var i = 1; i < passcode.length; i++) {
      final prev = passcode.codeUnitAt(i - 1) - 48;
      final curr = passcode.codeUnitAt(i) - 48;
      if (curr != prev + 1) ascending = false;
      if (curr != prev - 1) descending = false;
    }
    return ascending || descending;
  }

  bool _isRepetitive(String passcode) {
    final first = passcode[0];
    return passcode.split('').every((c) => c == first);
  }

  /// Returns a human-readable validation error, or null if [passcode] is
  /// valid — exposed so signup/login forms can validate before submitting,
  /// using the exact same rule set [savePasscode] enforces.
  String? passcodeValidationError(String passcode, {String? phoneNumber}) {
    try {
      _validatePasscode(passcode, phoneNumber: phoneNumber);
      return null;
    } on StorageException catch (e) {
      return e.message;
    }
  }

  /// Saves the user's passcode securely.
  ///
  /// Steps:
  ///   1. Validate the passcode meets the server's complexity rules.
  ///   2. Generate a random salt.
  ///   3. Hash the passcode with the salt.
  ///   4. Store "salt:hash:iterations" in encrypted storage.
  ///
  /// [phoneNumber], when provided, is used only for the "doesn't contain
  /// phone number" validation rule above — it is never stored.
  Future<void> savePasscode(String passcode, {String? phoneNumber}) async {
    try {
      _validatePasscode(passcode, phoneNumber: phoneNumber); // Step 1 — throws if invalid

      final salt = _generateSalt();         // Step 2
      const iterations = 10000;
      final hash = _hashPasscode(           // Step 3
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
  Future<void> savePin(String pin, {String? phoneNumber}) =>
      savePasscode(pin, phoneNumber: phoneNumber);

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

      final enteredHash = _hashPasscode(enteredPasscode, salt, iterations: iterations);

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

Future<bool> changePin({required String oldPin, required String newPin}) async {
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

  // ---------------------------------------------------------------------------
  // BIOMETRIC LOGIN CREDENTIAL
  // ---------------------------------------------------------------------------
  // The auth-service has no biometric login endpoint — a fingerprint/face can
  // only unlock something already on the device. So that a fingerprint can log
  // the user back in after a logout or an expired session, the identifier +
  // passcode that last logged in successfully are kept in secure storage
  // (Keystore/Keychain) and replayed through the normal POST /auth/login once
  // the OS biometric prompt succeeds. Only ever written while biometrics are
  // enabled; deleted when they are disabled, the passcode changes, or the
  // server rejects it. Never touched by clearAuth().

  Future<void> saveBiometricCredential(BiometricCredential credential) async {
    await _secureStorage.write(
      key: _biometricCredentialKey,
      value: jsonEncode(credential.toJson()),
    );
  }

  Future<BiometricCredential?> getBiometricCredential() async {
    try {
      final raw = await _secureStorage.read(key: _biometricCredentialKey);
      if (raw == null || raw.isEmpty) return null;
      return BiometricCredential.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteBiometricCredential() async {
    await _secureStorage.delete(key: _biometricCredentialKey);
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

  /// Clears everything [clearAll] does EXCEPT what belongs to this device
  /// rather than to the signed-in session: the device fingerprint, the
  /// biometric preference, and the biometric login credential.
  ///
  /// Use this on an explicit logout. Wiping the fingerprint there made the
  /// server see a brand-new device on the very next login and answer with a
  /// DEVICE_LINK OTP challenge every time, and wiping the biometric items made
  /// biometric login impossible after any logout.
  Future<void> clearSessionKeepingDevice() async {
    final fingerprint = await _secureStorage.read(key: _deviceFingerprintKey);
    final biometric = await _secureStorage.read(key: _biometricKey);
    final credential = await _secureStorage.read(key: _biometricCredentialKey);

    await clearAll();

    if (fingerprint != null) {
      await _secureStorage.write(key: _deviceFingerprintKey, value: fingerprint);
    }
    if (biometric != null) {
      await _secureStorage.write(key: _biometricKey, value: biometric);
    }
    if (credential != null) {
      await _secureStorage.write(
          key: _biometricCredentialKey, value: credential);
    }
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
      await prefs.setString(_completedRequirementsKey, jsonEncode(requirements));
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

// =============================================================================
// BiometricCredential
// -----------------------------------------------------------------------------
// What a successful biometric prompt replays through POST /auth/login. See
// StorageService.saveBiometricCredential for why this exists and its lifecycle.
// [customerId] ties it to the account that enrolled, so a different account
// signing in on the same device can never inherit it.
// =============================================================================

class BiometricCredential {
  final String customerId;
  final String identifier;
  final String passcode;

  const BiometricCredential({
    required this.customerId,
    required this.identifier,
    required this.passcode,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'identifier': identifier,
        'passcode': passcode,
      };

  factory BiometricCredential.fromJson(Map<String, dynamic> json) =>
      BiometricCredential(
        customerId: json['customerId'] as String,
        identifier: json['identifier'] as String,
        passcode: json['passcode'] as String,
      );
}