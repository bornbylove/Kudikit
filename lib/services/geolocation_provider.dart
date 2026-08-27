// lib/services/geolocation_provider.dart
// ─────────────────────────────────────────────────────────────────────────────
// SLICE 6 (MO-5) — GPS / geolocation provider abstraction.
//
// The address-verification flow must NOT depend on `geolocator` / `geocoding`
// (or any concrete geolocation backend) directly. Instead it depends on this
// [GeolocationProvider] interface. The concrete source is swappable at runtime /
// build time:
//
//   GeolocationProvider
//       ├── MobileGeolocationProvider  → wraps the existing lib/services/geo_service.dart
//       └── BackendGeolocationProvider → resolves coordinates via a backend geolocation API
//
// The address domain (AddressVerificationRequest, verify_address.dart) only
// ever touches [GeoCoordinates] and this interface — geolocator/geocoding
// imports stay confined inside MobileGeolocationProvider.
//
// Provider selection is configurable via the build-time define
// KUDIKIT_GEOLOCATION_SOURCE (defaults to "mobile"):
//   flutter run --dart-define=KUDIKIT_GEOLOCATION_SOURCE=backend
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:kudipay/services/geo_service.dart';

/// Pure coordinate value — the ONLY geolocation type the address domain uses.
/// Deliberately free of any geolocator/geocoding types.
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({required this.latitude, required this.longitude});

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoordinates($latitude, $longitude)';
}

/// Provider abstraction the address flow depends on (Slice 6).
abstract class GeolocationProvider {
  /// Human-readable source identifier (for diagnostics/selection).
  String get name;

  /// Whether this provider is available in the current build/runtime.
  bool get isAvailable;

  /// Best-effort current device coordinates. Returns null when unavailable
  /// (permission denied / service disabled / backend unreachable) — callers
  /// MUST treat coordinates as optional.
  Future<GeoCoordinates?> getCurrentCoordinates();

  /// Reverse-geocode coordinates to a human-readable address line.
  Future<String?> getAddressFromCoordinates(GeoCoordinates coordinates);

  /// Forward-geocode a free-form address string to coordinates.
  Future<GeoCoordinates?> getCoordinatesFromAddress(String address);
}

/// Device-geolocation implementation that wraps the existing [GeoService]
/// (geolocator + geocoding). No existing functionality is discarded.
class MobileGeolocationProvider implements GeolocationProvider {
  final GeoService _geoService;

  MobileGeolocationProvider([GeoService? geoService])
      : _geoService = geoService ?? GeoService();

  @override
  String get name => 'mobile';

  @override
  bool get isAvailable => true;

  @override
  Future<GeoCoordinates?> getCurrentCoordinates() async {
    try {
      final position = await _geoService.getCurrentLocation();
      if (position == null) return null;
      return GeoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on geolocator.LocationServiceDisabledException {
      return null;
    } on geolocator.PermissionDeniedException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getAddressFromCoordinates(GeoCoordinates coordinates) async {
    final address = await _geoService
        .getAddressFromCoordinates(coordinates.latitude, coordinates.longitude);
    return address == 'Unknown location' ? null : address;
  }

  @override
  Future<GeoCoordinates?> getCoordinatesFromAddress(String address) async {
    try {
      final latLng = await _geoService.getCoordinatesFromAddress(address);
      if (latLng == null) return null;
      return GeoCoordinates(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Backend-geolocation implementation. This is the OPTION B source prepared for
/// a later switch: coordinates/address are resolved by a backend geolocation
/// API instead of the device. Kept structurally complete but non-fatal — with
/// no backend endpoint wired it resolves to null (manual-entry fallback).
class BackendGeolocationProvider implements GeolocationProvider {
  final String? _endpoint;

  BackendGeolocationProvider({String? endpoint}) : _endpoint = endpoint;

  @override
  String get name => 'backend';

  @override
  bool get isAvailable {
    final endpoint = _endpoint;
    return endpoint != null && endpoint.isNotEmpty;
  }

  @override
  Future<GeoCoordinates?> getCurrentCoordinates() async {
    // No backend geolocation endpoint exists yet — resolve to null so the
    // address flow falls back to manual entry instead of breaking.
    return null;
  }

  @override
  Future<String?> getAddressFromCoordinates(GeoCoordinates coordinates) async {
    return null;
  }

  @override
  Future<GeoCoordinates?> getCoordinatesFromAddress(String address) async {
    return null;
  }
}

// ── Provider selection ──────────────────────────────────────────────────────
// Configurable at build time (KUDIKIT_GEOLOCATION_SOURCE=mobile|backend) so the
// address flow can switch sources without any change to its own code.

const String _geolocationSource = String.fromEnvironment(
  'KUDIKIT_GEOLOCATION_SOURCE',
  defaultValue: 'mobile',
);

final geolocationProvider = Provider<GeolocationProvider>((ref) {
  if (_geolocationSource == 'backend') {
    return BackendGeolocationProvider();
  }
  return MobileGeolocationProvider();
});