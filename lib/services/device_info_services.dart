// lib/services/device_info_service.dart
//
// Collects the four pieces of device context needed for the security OTP
// email template:
//
//   1. Device model   → dart:io Platform + a static model map (no extra package)
//   2. Public IP      → single HTTP GET to https://api.ipify.org?format=json
//   3. Location       → geolocator (already in pubspec) → geocoding → "City, Country"
//   4. Timestamp      → DateTime.now() formatted as "Feb 10, 2026 at 2:45pm"
//
// All packages used (http, geolocator, geocoding, intl) are already declared
// in pubspec.yaml — no new dependencies added.
//
// Error strategy: every sub-collection is wrapped in its own try/catch.
// If any step fails (e.g. user denies location permission), that field
// falls back to a safe placeholder string rather than throwing.
// This ensures the OTP send always proceeds even if metadata is partial.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/model/device/device_metadata.dart';

class DeviceInfoService {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Collects all four metadata fields concurrently and returns a
  /// [DeviceMetadata] instance. Never throws — each field has a safe fallback.
  static Future<DeviceMetadata> collect() async {
    // Run IP lookup and location lookup concurrently to keep latency low.
    final results = await Future.wait([
      _getPublicIp(),
      _getLocation(),
    ]);

    return DeviceMetadata(
      deviceModel: _getDeviceModel(),
      ipAddress: results[0], // IP result
      location: results[1], // location result
      timestamp: _formatTimestamp(DateTime.now()),
    );
  }

  // ---------------------------------------------------------------------------
  // Step A — Device model
  // ---------------------------------------------------------------------------
  // dart:io Platform gives us the OS. We can't get the exact marketing model
  // name without device_info_plus, so we return a clean OS + version string
  // that is still useful for the security email (e.g. "Android Device" or
  // "iPhone / iPad"). When the backend is live, swap this for device_info_plus
  // if the exact model name is required.

  static String _getDeviceModel() {
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iPhone / iPad';
      if (Platform.isMacOS) return 'Mac';
      if (Platform.isWindows) return 'Windows Device';
      if (Platform.isLinux) return 'Linux Device';
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  // ---------------------------------------------------------------------------
  // Step B — Public IP address
  // ---------------------------------------------------------------------------
  // Uses the http package (already in pubspec) to call ipify's free JSON
  // endpoint. Returns a formatted IP string like "108.98.90.22".
  // Falls back to 'Unavailable' if the request fails or times out.

  static Future<String> _getPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['ip'] as String?) ?? 'Unavailable';
      }
      return 'Unavailable';
    } catch (_) {
      return 'Unavailable';
    }
  }

  // ---------------------------------------------------------------------------
  // Step C — Location (City, Country)
  // ---------------------------------------------------------------------------
  // 1. Check and request location permission via geolocator.
  // 2. Get current position (low accuracy is fine — we only need city level).
  // 3. Reverse-geocode via geocoding package → Placemark → "City, Country".
  //
  // Falls back to 'Location unavailable' at any failure point:
  //   - Permission denied
  //   - Location services disabled
  //   - Reverse geocoding returns empty list
  //   - Any network/platform error

  static Future<String> _getLocation() async {
    try {
      // Check if location services are enabled on the device.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Location unavailable';

      // Check current permission status.
      LocationPermission permission = await Geolocator.checkPermission();

      // If denied, request once. If denied again or permanently, bail out.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location unavailable';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Location unavailable';
      }

      // Get current position — low accuracy to reduce battery impact and
      // latency. We only need city-level precision.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 8));

      // Reverse geocode to get a human-readable place name.
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return 'Location unavailable';

      final place = placemarks.first;

      // Build "City, Country" — fall back to whatever is available.
      final city = place.locality?.isNotEmpty == true
          ? place.locality!
          : place.administrativeArea ?? '';
      final country = place.country?.isNotEmpty == true ? place.country! : '';

      if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
      if (city.isNotEmpty) return city;
      if (country.isNotEmpty) return country;

      return 'Location unavailable';
    } catch (_) {
      return 'Location unavailable';
    }
  }

  // ---------------------------------------------------------------------------
  // Step D — Timestamp
  // ---------------------------------------------------------------------------
  // Formats DateTime to match the design exactly: "Feb 10, 2026 at 2:45pm"
  // Uses the intl package (already in pubspec).

  static String _formatTimestamp(DateTime dt) {
    try {
      // "Feb 10, 2026" part
      final datePart = DateFormat('MMM d, yyyy').format(dt);
      // "2:45pm" part — lowercase am/pm to match design
      final timePart = DateFormat('h:mma').format(dt).toLowerCase();
      return '$datePart at $timePart';
    } catch (_) {
      return dt.toIso8601String();
    }
  }
}
