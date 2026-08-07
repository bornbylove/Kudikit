enum Flavor {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._();

  static Flavor _flavor = Flavor.development;
  static bool _initialized = false;

  static void initialize({
    required Flavor flavor,
  }) {
    if (_initialized) {
      throw StateError('AppConfig has already been initialized.');
    }

    _flavor = flavor;
    _initialized = true;
  }

  static const _urls = {
    Flavor.development: 'http://199.192.22.72:8090/api/v1',
    Flavor.staging: 'https://staging-api.kudikit.com/api/v1',
    Flavor.production: 'https://api.kudikit.com/api/v1',
  };

  static String get baseUrl {
    const override = String.fromEnvironment('API_URL');
    if (override.isNotEmpty) {
      final uri = Uri.tryParse(override);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        return override;
      }
      throw FormatException('Invalid API_URL: $override');
    }

    return _urls[_flavor]!;
  }

  static bool get isDevelopment => _flavor == Flavor.development;
  static bool get isStaging => _flavor == Flavor.staging;
  static bool get isProduction => _flavor == Flavor.production;
}
