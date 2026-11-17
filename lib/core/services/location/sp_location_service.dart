import 'dart:async';

import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/location/place_details_service.dart';

enum SpLocationFetchStatus {
  success,
  denied,
  deniedForever,
  serviceDisabled,
  failed,
}

class SpLocationFetchResult {
  const SpLocationFetchResult({
    required this.status,
    this.place,
  });

  final SpLocationFetchStatus status;
  final PlaceDbModel? place;

  bool get isSuccess => status == SpLocationFetchStatus.success && place != null;
}

/// Core location service (no app UI concerns).
///
/// This layer only talks to platform location/geocoding APIs and returns data/status.
/// User-facing permission recovery UX belongs in [SpAppLocationService].
///
/// ## Low-connectivity design
/// This service is optimised for travel use cases where GPS works but internet
/// is slow or absent (e.g. roaming abroad, remote areas).
///
/// The priority order is:
///   1. **Coordinates first** — lat/lon is saved to the entry immediately.
///      GPS works offline; we should never let a network wait block a save.
///   2. **Reverse geocoding is best-effort** — it runs after coordinates are
///      captured and is bounded by [geocodeTimeout]. On timeout/failure the
///      entry is saved with coords only; no data is lost.
///   3. **Label can be filled later** — the Map tab auto-retries geocoding
///      when opened and the user can always type a custom name via the edit-
///      label flow, regardless of connectivity.
///
/// A story's place never waits for its name: it's saved with coordinates, and the name is
/// looked up after (see `PlaceDetailsService`, shared with the Map tab).
class SpLocationService {
  const SpLocationService._();

  /// Max time to wait for a fresh GPS fix before falling back to the last
  /// known position. Keeps location capture fast on low/no signal.
  static const Duration gpsTimeout = Duration(seconds: 5);

  /// Max time to wait for reverse geocoding before saving coordinates only.
  /// The user can fill the label later via the Map tab.
  static const Duration geocodeTimeout = Duration(seconds: 2);

  /// Requests permission (if needed), gets the device GPS position,
  /// and reverse-geocodes it into a [PlaceDbModel].
  ///
  /// Returns `null` when permission is denied, GPS is unavailable,
  /// or an error occurs.
  static Future<SpLocationFetchResult> fetchCurrentPlace({
    bool requestPermission = true,
    bool skipReverseGeocoding = false,
  }) async {
    try {
      final access = await checkAccess(requestPermission: requestPermission);
      if (access != SpLocationFetchStatus.success) return SpLocationFetchResult(status: access);

      final latLng = await fetchFreshLatLng();
      if (latLng == null) {
        return const SpLocationFetchResult(status: SpLocationFetchStatus.failed);
      }

      PlaceDbModel? place;

      if (!skipReverseGeocoding) {
        // One of the user's own places first (local, instant, the same rule as one-tap), else the geocoder.
        place = await PlaceDetailsService.savedPlaceAtCurrentLocation(latLng);
        // Bound the network geocode: on timeout/failure we save coordinates
        // only, and the label can be filled later from the Map tab.
        if (place == null) {
          try {
            place = await SpGeocodingService.systemInstance.reverseGeocode(latLng).timeout(geocodeTimeout);
          } catch (_) {
            place = null;
          }
        }
      }

      place ??= PlaceDbModel(latitude: latLng.latitude, longitude: latLng.longitude);

      return SpLocationFetchResult(
        status: SpLocationFetchStatus.success,
        place: place,
      );
    } catch (_) {
      return const SpLocationFetchResult(status: SpLocationFetchStatus.failed);
    }
  }

  /// Whether location can be read: [SpLocationFetchStatus.success], or why not. With [requestPermission],
  /// asks for access when it hasn't been decided yet (the system prompt).
  static Future<SpLocationFetchStatus> checkAccess({bool requestPermission = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return SpLocationFetchStatus.serviceDisabled;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      return switch (permission) {
        LocationPermission.deniedForever => SpLocationFetchStatus.deniedForever,
        LocationPermission.denied => SpLocationFetchStatus.denied,
        _ => SpLocationFetchStatus.success,
      };
    } catch (_) {
      return SpLocationFetchStatus.failed;
    }
  }

  /// A fresh GPS fix, but never longer than [gpsTimeout]: on low signal, the last known position instead
  /// (so coordinates can still be saved quickly). Null when there's neither. Expects access (see [checkAccess]).
  static Future<SpLatLng?> fetchFreshLatLng() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(gpsTimeout);
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }

      return position == null ? null : SpLatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Reads only last-known coordinates without reverse geocoding — instant, no GPS. Null without access,
  /// or when the position is older than [maxAge] (an old one may be in another city).
  ///
  /// Use this for fast, initial camera positioning where coordinates are enough.
  static Future<SpLatLng?> fetchLastKnownLocation({Duration? maxAge}) async {
    try {
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      if (maxAge != null && DateTime.now().difference(position.timestamp) > maxAge) return null;

      return SpLatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// The distance between [a] and [b], in meters.
  static double distanceBetween(SpLatLng a, SpLatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  static Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
