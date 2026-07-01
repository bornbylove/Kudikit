// lib/model/device/device_metadata.dart
//
// Holds the device context that is attached to security-sensitive OTP requests
// so the backend can populate the full email template (Image 1 design):
//
//   Time      → Feb 10, 2026 at 2:45pm
//   Device    → iPhone 14 Pro
//   Location  → Lagos, Nigeria
//   IP Address → 108.98.90
//
// Usage:
//   final meta = await DeviceInfoService.collect();
//   final body = { ...otherFields, ...meta.toJson() };
//
// The backend decides which email template to render based on whether
// the 'device_metadata' key is present in the request payload.

class DeviceMetadata {
  /// Human-readable device model, e.g. "iPhone 14 Pro" or "Samsung Galaxy S23"
  final String deviceModel;

  /// Public IP address of the device at the time of the request
  final String ipAddress;

  /// City + country resolved from coordinates, e.g. "Lagos, Nigeria"
  final String location;

  /// Formatted timestamp, e.g. "Feb 10, 2026 at 2:45pm"
  final String timestamp;

  const DeviceMetadata({
    required this.deviceModel,
    required this.ipAddress,
    required this.location,
    required this.timestamp,
  });

  /// Produces the nested map that goes into the API request body under
  /// the key 'device_metadata'. Field names match the backend contract.
  Map<String, dynamic> toJson() => {
        'device_metadata': {
          'device_model': deviceModel,
          'ip_address': ipAddress,
          'location': location,
          'timestamp': timestamp,
        },
      };

  /// Convenience: merges device_metadata into an existing payload map.
  /// Example:
  ///   final body = meta.mergeInto({'email': email, 'otp_type': 'device_link'});
  Map<String, dynamic> mergeInto(Map<String, dynamic> payload) => {
        ...payload,
        ...toJson(),
      };

  @override
  String toString() => 'DeviceMetadata(device: $deviceModel, ip: $ipAddress, '
      'location: $location, time: $timestamp)';
}
