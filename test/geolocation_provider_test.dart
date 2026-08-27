// test/geolocation_provider_test.dart
//
// Slice 6 (MO-5): the address flow must depend on the GeolocationProvider
// abstraction, never on geolocator/geocoding directly. Verifies the pure
// GeoCoordinates value, the BackendGeolocationProvider fallback semantics,
// the default provider selection, and the MobileGeolocationProvider's
// error-to-null mapping (permission denial / service disabled never throw
// through to the address form — coordinates stay optional).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kudipay/services/geo_service.dart';
import 'package:kudipay/services/geolocation_provider.dart';

class _ThrowingGeoService implements GeoService {
  final bool throwDisabled;

  _ThrowingGeoService({this.throwDisabled = false});

  @override
  Position? get currentPosition => null;

  @override
  Future<Position?> getCurrentLocation() async {
    if (throwDisabled) throw const LocationServiceDisabledException();
    throw const PermissionDeniedException('denied');
  }

  @override
  Stream<Position> getLocationStream() => const Stream.empty();

  @override
  double calculateDistance(
          double startLat, double startLng, double endLat, double endLng) =>
      0;

  @override
  LatLng positionToLatLng(Position position) => throw UnimplementedError();

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    throw StateError('unreachable');
  }

  @override
  Future<LatLng?> getCoordinatesFromAddress(String address) async => null;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<void> openAppSettings() async {}
}

void main() {
  group('GeoCoordinates (pure value)', () {
    test('equality is value-based', () {
      const a = GeoCoordinates(latitude: 6.5, longitude: 3.4);
      const b = GeoCoordinates(latitude: 6.5, longitude: 3.4);
      const c = GeoCoordinates(latitude: 6.0, longitude: 3.4);
      expect(a, equals(b));
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('BackendGeolocationProvider (Slice 6 — prepared, non-fatal)', () {
    test('unavailable without an endpoint; every resolution is null', () async {
      final provider = BackendGeolocationProvider();
      expect(provider.name, 'backend');
      expect(provider.isAvailable, isFalse);
      expect(await provider.getCurrentCoordinates(), isNull);
      expect(
          await provider.getAddressFromCoordinates(
              const GeoCoordinates(latitude: 6.5, longitude: 3.4)),
          isNull);
      expect(await provider.getCoordinatesFromAddress('Lagos'), isNull);
    });

    test('available when an endpoint is configured', () {
      expect(BackendGeolocationProvider(endpoint: 'https://geo.test')
          .isAvailable, isTrue);
    });
  });

  group('MobileGeolocationProvider (wraps GeoService)', () {
    test('permission/service errors map to null — coordinates stay optional',
        () async {
      final disabled = MobileGeolocationProvider(_ThrowingGeoService(throwDisabled: true));
      expect(await disabled.getCurrentCoordinates(), isNull);

      final denied = MobileGeolocationProvider(_ThrowingGeoService());
      expect(await denied.getCurrentCoordinates(), isNull);
    });

    test('exposes the mobile source name and is always available', () {
      expect(MobileGeolocationProvider().name, 'mobile');
      expect(MobileGeolocationProvider().isAvailable, isTrue);
    });
  });

  group('geolocationProvider selection (build-time source)', () {
    test('defaults to the mobile source', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = container.read(geolocationProvider);
      expect(provider, isA<MobileGeolocationProvider>());
      expect(provider.name, 'mobile');
    });
  });
}