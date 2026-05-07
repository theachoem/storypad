import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/services/geocoding/sp_null_geocoding_service.dart';
import 'package:storypad/core/services/geocoding/system/sp_system_geocoding_service.dart';

/// Abstract interface for reverse geocoding and place search.
///
/// Business logic should ONLY interact with geocoding through the
/// [geocodingService] singleton — never import concrete implementations.
///
/// ## Architecture
/// ```
/// ViewModel / Service
///     ↓
/// SpGeocodingService (abstract)
///     ↓ (singleton factory selects by platform)
/// SpSystemGeocodingService   ← iOS / Android / macOS  (system geocoder, free)
/// SpNullGeocodingService     ← Linux / Windows / Web  (no-op)
/// ```
abstract class SpGeocodingService {
  /// Platform-selected [SpGeocodingService] singleton.
  ///
  /// - iOS / Android / macOS → [SpSystemGeocodingService] (system geocoder, free)
  /// - Linux / Windows / Web → [SpNullGeocodingService] (no-op)
  static final instance = (!kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS))
      ? SpSystemGeocodingService()
      : const SpNullGeocodingService();

  /// Convert coordinates to a human-readable place.
  ///
  /// Returns `null` when the platform does not support geocoding or the
  /// coordinates cannot be resolved.
  Future<PlaceDbModel?> reverseGeocode(SpLatLng latLng);

  /// Search for places matching [query].
  ///
  /// Returns an empty list when geocoding is unavailable.
  Future<List<PlaceDbModel>> searchPlaces(String query);

  /// Tries to resolve a nearby saved place from local stories.
  ///
  /// Uses a local coordinate window only (no meter distance calculation).
  /// Returns the first place found within the window, otherwise `null`.
  static Future<PlaceDbModel?> reverseGeocodeViaDb(
    SpLatLng latLng, {
    double latitudeDelta = 0.00027,
    double longitudeDelta = 0.00027,
    int fetchLimit = 1,
  }) async {
    final bounds = SpLatLngBounds(
      south: (latLng.latitude - latitudeDelta).clamp(-90.0, 90.0),
      west: (latLng.longitude - longitudeDelta).clamp(-180.0, 180.0),
      north: (latLng.latitude + latitudeDelta).clamp(-90.0, 90.0),
      east: (latLng.longitude + longitudeDelta).clamp(-180.0, 180.0),
    );

    final nearbyStories = await StoryDbModel.db.getStoriesWithLocation(bounds: bounds, limit: fetchLimit);
    if (nearbyStories.isEmpty) return null;

    final firstMatch = nearbyStories.first;
    return PlaceDbModel(
      latitude: firstMatch.location.latitude,
      longitude: firstMatch.location.longitude,
      placeName: firstMatch.placeName,
    );
  }
}
