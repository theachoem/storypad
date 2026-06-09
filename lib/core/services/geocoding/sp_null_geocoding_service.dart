import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';

/// No-op [SpGeocodingService] used on platforms where no geocoding is
/// available (Linux, Windows).
///
/// Returns `null` / empty list for all calls. Replace with a concrete
/// API-backed implementation when a geocoding API key is configured.
class SpNullGeocodingService implements SpGeocodingService {
  const SpNullGeocodingService();

  @override
  Future<PlaceDbModel?> reverseGeocode(SpLatLng latLng) async => null;

  @override
  Future<List<PlaceDbModel>> searchPlaces(String query, {SpLatLng? proximity}) async => [];
}
