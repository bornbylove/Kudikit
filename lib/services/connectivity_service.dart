import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:kudipay/config/dio_client.dart' show ConnectivityChecker;

class ConnectivityService implements ConnectivityChecker {
  ConnectivityService._privateConstructor();
  static final ConnectivityService instance = ConnectivityService._privateConstructor();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();
  final _connectionChangeController = StreamController<bool>.broadcast();

  bool _hasConnection = false;
  Stream<bool> get connectionChange => _connectionChangeController.stream;
  bool get hasConnection => _hasConnection;

  Future<void> initialize() async {
    _hasConnection = await hasInternetConnection();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasInternet = await hasInternetConnection();
    if (_hasConnection != hasInternet) {
      _hasConnection = hasInternet;
      _connectionChangeController.add(_hasConnection);
    }
  }

  // Checks genuine internet reachability — deliberately NOT tied to our own
  // backend. This feeds the app-wide "are we online" signal used by many
  // unrelated screens (see connectivity_provider.dart), so it must not
  // depend on one specific host being up. Whether *our* backend specifically
  // is reachable is a different question, already answered per-request by
  // DioClient's typed exceptions (KudiNetworkException/KudiServerException/
  // KudiTimeoutException) — conflating the two here previously caused a
  // false "No internet" banner whenever the staging box was briefly
  // unreachable (e.g. a real device/emulator without a route to that
  // internal IP) even though the device's actual internet was fine.
  @override
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) return false;
      return await _internetChecker.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  Future<List<ConnectivityResult>> getConnectivityType() =>
      _connectivity.checkConnectivity();

  void dispose() => _connectionChangeController.close();
}

extension ConnectivityExtension on ConnectivityResult {
  String get displayName {
    switch (this) {
      case ConnectivityResult.wifi: return 'WiFi';
      case ConnectivityResult.mobile: return 'Mobile Data';
      case ConnectivityResult.ethernet: return 'Ethernet';
      case ConnectivityResult.vpn: return 'VPN';
      case ConnectivityResult.bluetooth: return 'Bluetooth';
      case ConnectivityResult.other: return 'Other';
      case ConnectivityResult.none: return 'No Connection';
      default: return 'Unknown';
    }
  }
}