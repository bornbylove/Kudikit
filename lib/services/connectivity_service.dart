import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Service to manage internet connectivity checking
///
/// This service provides methods to:
/// - Check current connectivity status
/// - Monitor connectivity changes in real-time
/// - Verify actual internet access (not just network connection)
class ConnectivityService {
  // Singleton pattern
  ConnectivityService._privateConstructor();
  static final ConnectivityService instance =
      ConnectivityService._privateConstructor();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  // Stream controller for connectivity changes
  final _connectionChangeController = StreamController<bool>.broadcast();

  // Current connectivity status
  bool _hasConnection = false;

  /// Stream of connectivity changes
  Stream<bool> get connectionChange => _connectionChangeController.stream;

  /// Current connection status
  bool get hasConnection => _hasConnection;

  /// Initialize the connectivity service
  /// Call this in your main.dart before runApp()
  Future<void> initialize() async {
    // Check initial connectivity
    _hasConnection = await hasInternetConnection();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Also listen to internet connection checker for more accurate results
    _internetChecker.onStatusChange.listen((status) {
      final hasInternet = status == InternetStatus.connected;
      if (_hasConnection != hasInternet) {
        _hasConnection = hasInternet;
        _connectionChangeController.add(_hasConnection);
      }
    });
  }

  /// Update connection status when network changes
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // Check if we have actual internet access, not just network connection
    final hasInternet = await hasInternetConnection();

    if (_hasConnection != hasInternet) {
      _hasConnection = hasInternet;
      _connectionChangeController.add(_hasConnection);
    }
  }

  /// Check if device has internet connection
  ///
  /// This performs an actual internet check by trying to reach
  /// reliable servers, not just checking if WiFi/Mobile data is on
  Future<bool> hasInternetConnection() async {
    try {
      // First check if we have any connectivity at all
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Then verify we can actually reach the internet
      return await _internetChecker.hasInternetAccess;
    } catch (e) {
      // If there's an error, assume no connection
      return false;
    }
  }

  /// Get the current connectivity type
  /// Returns: wifi, mobile, ethernet, bluetooth, vpn, other, or none
  Future<List<ConnectivityResult>> getConnectivityType() async {
    return await _connectivity.checkConnectivity();
  }

  /// Check if connected via WiFi
  Future<bool> isConnectedViaWiFi() async {
    final result = await getConnectivityType();
    return result.contains(ConnectivityResult.wifi);
  }

  /// Check if connected via mobile data
  Future<bool> isConnectedViaMobile() async {
    final result = await getConnectivityType();
    return result.contains(ConnectivityResult.mobile);
  }

  /// Dispose resources when no longer needed
  void dispose() {
    _connectionChangeController.close();
  }
}

/// Extension methods for easier connectivity checking
extension ConnectivityExtension on ConnectivityResult {
  /// Check if this connectivity type has potential internet
  bool get hasPotentialInternet {
    return this != ConnectivityResult.none;
  }

  /// Get a human-readable name for the connectivity type
  String get displayName {
    switch (this) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return "unknown";
    }
  }
}
