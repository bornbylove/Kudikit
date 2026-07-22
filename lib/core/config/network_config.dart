// lib/core/config/network_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// Network / API base configuration.
//
// Moved here from lib/config/env.dart as part of the core/ consolidation.
// The base URL can be overridden at build time:
//   flutter run --dart-define=API_URL=https://api.example.com
// ─────────────────────────────────────────────────────────────────────────────

const String kBaseUrl = String.fromEnvironment('API_URL',
    defaultValue: 'http://159.198.75.72:8086');
