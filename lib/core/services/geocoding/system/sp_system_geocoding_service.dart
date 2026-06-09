import 'package:geocoding/geocoding.dart' as geo;
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// [SpGeocodingService] implementation using the system geocoder via the
/// `geocoding` package.
///
/// Supported platforms: iOS, Android, macOS.
class SpSystemGeocodingService implements SpGeocodingService {
  @override
  Future<PlaceDbModel?> reverseGeocode(SpLatLng latLng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isEmpty) return null;
      final p = placemarks.first;

      // Build a readable address from available components.
      final addressParts = <String>[
        if (p.name != null && p.name!.isNotEmpty) p.name!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.country != null && p.country!.isNotEmpty) p.country!,
      ];

      return PlaceDbModel(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        placeName: p.name?.isNotEmpty == true ? p.name : null,
        locality: p.locality?.isNotEmpty == true ? p.locality : p.subAdministrativeArea,
        country: p.country?.isNotEmpty == true ? p.country : null,
        isoCountryCode: p.isoCountryCode?.isNotEmpty == true ? p.isoCountryCode : null,
        address: addressParts.isNotEmpty ? addressParts.join(', ') : null,
      );
    } catch (e) {
      AppLogger.error('SpSystemGeocodingService.reverseGeocode error: $e');
      return null;
    }
  }

  @override
  Future<List<PlaceDbModel>> searchPlaces(
    String query, {
    SpLatLng? proximity, // Optional proximity hint for better search results
  }) async {
    try {
      final locations = await geo.locationFromAddress(query);
      return locations.map((loc) {
        return PlaceDbModel(
          latitude: loc.latitude,
          longitude: loc.longitude,
          // geocoding package doesn't return place names from forward geocoding
          address: query,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('SpSystemGeocodingService.searchPlaces error: $e');
      return [];
    }
  }
}
