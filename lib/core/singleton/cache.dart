// lib/core/singleton/cache.dart
// ─────────────────────────────────────────────────────────────────────────────
// Process-lifetime in-memory cache (a simple singleton key/value store).
//
// For PERSISTENT storage use CacheHelper (core/app/cache_helper.dart) for
// non-sensitive values, or StorageService (lib/services/storage_services.dart)
// for tokens / passcodes / user data.
// ─────────────────────────────────────────────────────────────────────────────

/// A minimal singleton in-memory cache. Values live only for the app session.
class Cache {
  Cache._();

  /// The shared instance.
  static final Cache instance = Cache._();

  final Map<String, Object?> _store = {};

  T? get<T>(String key) => _store[key] as T?;

  void set(String key, Object? value) => _store[key] = value;

  bool contains(String key) => _store.containsKey(key);

  void remove(String key) => _store.remove(key);

  void clear() => _store.clear();
}
