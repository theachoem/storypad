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
class SpLocationService {
  const SpLocationService._();

  /// Requests permission (if needed), gets the device GPS position,
  /// and reverse-geocodes it into a [PlaceDbModel].
  ///
  /// Returns `null` when permission is denied, GPS is unavailable,
  /// or an error occurs.
  static Future<PlaceDbModel?> fetchCurrentPlace({bool requestPermission = true}) async {
    final result = await fetchCurrentPlaceResult(requestPermission: requestPermission);
    return result.place;
  }

  /// Same location fetch as [fetchCurrentPlace] but with explicit status for UX.
  static Future<SpLocationFetchResult> fetchCurrentPlaceResult({bool requestPermission = true}) async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final latLng = SpLatLng(position.latitude, position.longitude);
      final place =
          await SpGeocodingService.instance.reverseGeocode(latLng) ??
          PlaceDbModel(latitude: position.latitude, longitude: position.longitude);

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
