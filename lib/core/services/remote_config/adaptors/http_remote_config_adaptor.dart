import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/services/remote_config/adaptors/base_remote_config_adaptor.dart';
import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

/// Caches the last-successfully-fetched remote config JSON on disk, so cold
/// starts never block on network and offline reads still return real values.
class RemoteConfigCacheStorage extends MapStorage {}

/// Fetches config from a single static JSON file (`static.storypad.me`)
/// instead of Firebase Remote Config. Reads defaults + disk cache
/// synchronously in [initialize], then fires a fire-and-forget refetch —
/// callers never block on network. Edge caching/staleness is handled by the
/// CDN's own `Cache-Control` headers, not client-side throttling.
class HttpRemoteConfigAdaptor extends BaseRemoteConfigAdaptor {
  final String baseUrl;
  final http.Client _httpClient;
  final RemoteConfigCacheStorage _cache;

  HttpRemoteConfigAdaptor({
    this.baseUrl = 'https://static.storypad.me',
    http.Client? httpClient,
    RemoteConfigCacheStorage? cache,
  }) : _httpClient = httpClient ?? http.Client(),
       _cache = cache ?? RemoteConfigCacheStorage();

  Map<String, dynamic> _values = {};
  final _updatesController = StreamController<Set<String>>.broadcast();

  @override
  Future<void> initialize(Map<String, dynamic> defaults) async {
    _values = Map.of(defaults);

    try {
      final cached = await _cache.readMap();
      if (cached != null) _values = {..._values, ...cached};
    } catch (error) {
      debugPrint('HttpRemoteConfigAdaptor#initialize cache read failed: $error');
    }

    unawaited(_refetchAndApply());
  }

  Future<void> _refetchAndApply() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$baseUrl/remote-config.json'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      _values = {..._values, ...decoded};
      await _cache.writeMap(decoded);
      _updatesController.add(decoded.keys.toSet());
    } catch (error) {
      debugPrint('HttpRemoteConfigAdaptor#_refetchAndApply: $error');
    }
  }

  @override
  String getString(String key, String defaultValue) {
    final value = _values[key];
    if (value is String) return value;
    return defaultValue;
  }

  @override
  bool getBool(String key, bool defaultValue) {
    final value = _values[key];
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  @override
  int getInt(String key, int defaultValue) {
    final value = _values[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  double getDouble(String key, double defaultValue) {
    final value = _values[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  String getJsonString(String key, String defaultValue) {
    final value = _values[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return jsonEncode(value);
  }

  @override
  Stream<Set<String>> get onConfigUpdated => _updatesController.stream;
}
