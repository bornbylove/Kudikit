import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// geolocator already exports LocationServiceDisabledException and
// PermissionDeniedException — do NOT redeclare them here. Importing
// geolocator is sufficient; the provider catches them by their
// geolocator-native types.

class GeoService {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Request location permissions and get precise user location.
  /// Throws geolocator's own [LocationServiceDisabledException] if the
  /// device location service is off, and [PermissionDeniedException] if
  /// the user denies the permission request.
  Future<Position?> getCurrentLocation() async {
    // 1 — Is the location service switched on at the OS level?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // geolocator's built-in exception — no redeclaration needed
      throw const LocationServiceDisabledException();
    }

    // 2 — Do we have (or can we get) the permission?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permissions are permanently denied. Please enable in app settings.',
      );
    }

    // 3 — Fetch precise position
    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return _currentPosition;
  }

  /// Stream real-time position updates (10 m filter to avoid excessive rebuilds).
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Straight-line distance between two coordinates, in kilometres.
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }

  /// Convert a [Position] to a Google Maps [LatLng].
  LatLng positionToLatLng(Position position) =>
      LatLng(position.latitude, position.longitude);

  /// Reverse-geocode coordinates to a human-readable street address.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.locality}';
      }
    } catch (_) {
      // ignore — return fallback below
    }
    return 'Unknown location';
  }

  /// Forward-geocode an address string to [LatLng].
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  /// Returns true if the app currently holds a location permission.
  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Opens the OS location-settings page so the user can toggle GPS.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app's settings page so the user can grant permissions.
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
