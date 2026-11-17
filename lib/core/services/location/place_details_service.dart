import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/map/place_selection_service.dart';

/// A place's details (name, locality, country, address) looked up for its coordinates. Shared by the
/// story (filling in a place saved with coordinates only) and the Map tab, so a spot is looked up once.
///
/// The geocoder's answers are kept in memory by spot (~11m), lookups still running included: asking
/// again joins the running one. Failures aren't kept, so a spot is retried once back online. Nothing is
/// kept across launches: the details end up saved in the story itself.
class PlaceDetailsService {
  const PlaceDetailsService._();

  /// A hung geocoder must not keep a lookup (and the Map tab's spinner) going forever.
  static const Duration geocodeTimeout = Duration(seconds: 10);

  static const int _maxSpots = 50;

  @visibleForTesting
  static Future<PlaceDbModel?> Function(SpLatLng latLng) reverseGeocode =
      SpGeocodingService.systemInstance.reverseGeocode;

  /// How close a spot is to one of the user's named places to take its name (~11m spots, a finger's drag).
  static const double namedPlaceRadius = 30.0;

  /// How close the current location is to one of the user's named places to be that place: GPS alone (offline,
  /// no Wi-Fi or cell help) is often this far off.
  static const double currentLocationRadius = 75.0;

  /// The user's nearest named place within [radius] meters, from their stories.
  @visibleForTesting
  static Future<PlaceDbModel?> Function(SpLatLng latLng, {double radius}) reverseGeocodeViaDb =
      (latLng, {double radius = namedPlaceRadius}) => SpGeocodingService.reverseGeocodeViaDb(latLng, radius: radius);

  // Most recently asked last, so the oldest spot is dropped first.
  static final LinkedHashMap<String, Future<PlaceDbModel?>> _geocoded = LinkedHashMap();

  /// [place] with its details looked up (see [PlaceSelectionService.mergeDetails]): the user's own name for
  /// a place within ~30m (from their stories, read fresh every time), and the geocoder's. Null if nothing's found.
  static Future<PlaceDbModel?> details(PlaceDbModel place) async {
    final (saved, geocoded) = await (_savedNear(place.latLng), geocode(place.latLng)).wait;
    return PlaceSelectionService.mergeDetails(place, saved: saved, geocoded: geocoded);
  }

  /// [place] with the user's own name for a place within ~30m, or null if there's none (or it has its own name).
  /// Local only, so instant and offline too: shown before [details], whose geocoder can take seconds.
  static Future<PlaceDbModel?> savedName(PlaceDbModel place) async {
    if (place.placeName?.trim().isNotEmpty == true) return null;
    final saved = await _savedNear(place.latLng);
    return saved == null ? null : PlaceSelectionService.mergeDetails(place, saved: saved);
  }

  /// The user's own place at the current location [latLng]: their nearest named place within
  /// [currentLocationRadius], reused as it is (its spot and name), as tapping its dot on the map would.
  /// Null if there's none. Local only.
  static Future<PlaceDbModel?> savedPlaceAtCurrentLocation(SpLatLng latLng) =>
      _savedNear(latLng, radius: currentLocationRadius);

  static Future<PlaceDbModel?> _savedNear(SpLatLng latLng, {double radius = namedPlaceRadius}) =>
      reverseGeocodeViaDb(latLng, radius: radius).catchError((_) => null);

  /// The geocoder's place for [latLng]'s spot: kept, or joined while still running. Never throws.
  static Future<PlaceDbModel?> geocode(SpLatLng latLng) {
    final key = spotKey(latLng);

    final kept = _geocoded.remove(key);
    if (kept != null) return _geocoded[key] = kept;

    final lookup = _lookup(latLng);
    _geocoded[key] = lookup;
    if (_geocoded.length > _maxSpots) _geocoded.remove(_geocoded.keys.first);

    // Not found (or offline): forget it, so the next ask tries again.
    lookup.then((place) {
      if (place == null && identical(_geocoded[key], lookup)) _geocoded.remove(key);
    });
    return lookup;
  }

  static Future<PlaceDbModel?> _lookup(SpLatLng latLng) async {
    try {
      return await reverseGeocode(latLng).timeout(geocodeTimeout);
    } catch (_) {
      return null;
    }
  }

  /// One key per ~11m spot.
  static String spotKey(SpLatLng latLng) =>
      '${latLng.latitude.toStringAsFixed(4)},${latLng.longitude.toStringAsFixed(4)}';

  @visibleForTesting
  static void reset() => _geocoded.clear();
}
