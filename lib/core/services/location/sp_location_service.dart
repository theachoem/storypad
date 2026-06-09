import 'dart:async';

import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';

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
///   3. **Label can be filled later** — the map editor auto-retries geocoding
///      when opened and the user can always type a custom name via the edit-
///      label flow, regardless of connectivity.
///
/// The same [geocodeTimeout] is reused in [MapPickerViewModel.buildConfirmResult]
/// to bound the confirm action, but NOT during interactive resolve (while the
/// user is viewing the map picker with a visible spinner).
class SpLocationService {
  const SpLocationService._();

  /// Max time to wait for a fresh GPS fix before falling back to the last
  /// known position. Keeps location capture fast on low/no signal.
  static const Duration gpsTimeout = Duration(seconds: 5);

  /// Max time to wait for reverse geocoding before saving coordinates only.
  /// The user can fill the label later via the map editor.
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const SpLocationFetchResult(status: SpLocationFetchStatus.serviceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const SpLocationFetchResult(status: SpLocationFetchStatus.deniedForever);
      }

      if (permission == LocationPermission.denied) {
        return const SpLocationFetchResult(status: SpLocationFetchStatus.denied);
      }

      // Prefer a fresh fix, but don't hang on low signal: fall back to the
      // last known position so we can still save coordinates quickly.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(gpsTimeout);
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return const SpLocationFetchResult(status: SpLocationFetchStatus.failed);
      }

      final latLng = SpLatLng(position.latitude, position.longitude);

      PlaceDbModel? place;

      if (!skipReverseGeocoding) {
        // Always prefer DB reverse geocoding first to avoid unnecessary API calls and latency.
        // User can still use reverseGeocode on map picker.
        place = await SpGeocodingService.reverseGeocodeViaDb(latLng);
        // Bound the network geocode: on timeout/failure we save coordinates
        // only, and the label can be filled later from the map editor.
        if (place == null) {
          try {
            place = await SpGeocodingService.systemInstance.reverseGeocode(latLng).timeout(geocodeTimeout);
          } catch (_) {
            place = null;
          }
        }
      }

      place ??= PlaceDbModel(latitude: position.latitude, longitude: position.longitude);

      return SpLocationFetchResult(
        status: SpLocationFetchStatus.success,
        place: place,
      );
    } catch (_) {
      return const SpLocationFetchResult(status: SpLocationFetchStatus.failed);
    }
  }

  /// Reads only last-known coordinates without reverse geocoding.
  ///
  /// Use this for fast, initial camera positioning where coordinates are enough.
  static Future<SpLatLng?> fetchLastKnownLocation() async {
    try {
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return SpLatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
