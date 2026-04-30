import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/geocoding/sp_place_result.dart';

/// No-op [SpGeocodingService] used on platforms where no geocoding is
/// available (Linux, Windows).
///
/// Returns `null` / empty list for all calls. Replace with a concrete
/// API-backed implementation when a geocoding API key is configured.
class SpNullGeocodingService implements SpGeocodingService {
  const SpNullGeocodingService();

  @override
  Future<SpPlaceResult?> reverseGeocode(SpLatLng latLng) async => null;

  @override
  Future<List<SpPlaceResult>> searchPlaces(String query) async => [];
}
