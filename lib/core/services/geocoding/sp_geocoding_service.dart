import 'dart:io';
import 'dart:math';

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
  static final systemInstance = (!kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS))
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
  Future<List<PlaceDbModel>> searchPlaces(
    String query, {
    SpLatLng? proximity, // Optional proximity hint for better search results
  });

  /// The nearest of the user's named places within [radius] meters of [latLng], from their stories, as saved.
  /// Local only.
  static Future<PlaceDbModel?> reverseGeocodeViaDb(
    SpLatLng latLng, {
    double radius = 30.0,
  }) async {
    // A box around the circle (its corners are trimmed by the distance check below).
    const double metersPerDegree = 111320.0;
    final latitudeDelta = radius / metersPerDegree;
    final longitudeDelta = radius / (metersPerDegree * max(cos(latLng.latitude * pi / 180.0).abs(), 0.01));
    final bounds = SpLatLngBounds(
      south: (latLng.latitude - latitudeDelta).clamp(-90.0, 90.0),
      west: (latLng.longitude - longitudeDelta).clamp(-180.0, 180.0),
      north: (latLng.latitude + latitudeDelta).clamp(-90.0, 90.0),
      east: (latLng.longitude + longitudeDelta).clamp(-180.0, 180.0),
    );

    // Each distinct place once, none left out (see getNamedPlaces), then the nearest: two of the user's places
    // can be close together.
    final places = await StoryDbModel.db.getNamedPlaces(bounds: bounds);
    final candidates = [
      for (final place in places)
        if (place.placeName?.trim().isNotEmpty == true && latLng.distanceTo(place.latLng) <= radius) place,
    ]..sort((a, b) => latLng.distanceTo(a.latLng).compareTo(latLng.distanceTo(b.latLng)));

    // As it's saved: its name and the details looked up for it.
    return candidates.firstOrNull;
  }
}
