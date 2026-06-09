import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// [SpGeocodingService] implementation using MapTiler Cloud API.
///
/// This service requires [kMapTilerApiKey] to be properly configured.
/// API documentation: https://docs.maptiler.com/cloud/api/geocoding/
class SpMapTilerGeocodingService implements SpGeocodingService {
  static const String _baseUrl = 'https://api.maptiler.com/geocoding';

  @override
  Future<PlaceDbModel?> reverseGeocode(SpLatLng latLng) async {
    try {
      // MapTiler reverse geocoding format: /{longitude},{latitude}.json
      final url = Uri.parse(
        '$_baseUrl/${latLng.longitude},${latLng.latitude}.json?key=$kMapTilerApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppLogger.error(
          'SpMapTilerGeocodingService.reverseGeocode API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      final features = data['features'] as List<dynamic>?;

      if (features == null || features.isEmpty) return null;

      // Use the most relevant (first) feature
      final p = features.first;
      final context = p['context'] as List<dynamic>? ?? [];
      final placeType = p['place_type'] as List<dynamic>? ?? [];

      String? placeName = p['text'];
      String? address = p['place_name'];
      String? locality;
      String? country;

      // Helper function to extract hierarchical data from the MapTiler `context` array
      String? extractFromContext(String type) {
        final ctxItem = context.firstWhere(
          (c) => (c['id'] as String).startsWith('$type.'),
          orElse: () => null,
        );
        return ctxItem != null ? ctxItem['text'] as String? : null;
      }

      // Determine locality based on the primary feature type or the context
      if (placeType.contains('locality') || placeType.contains('place') || placeType.contains('city')) {
        locality = placeName;
      } else {
        locality = extractFromContext('locality') ?? extractFromContext('place') ?? extractFromContext('city');
      }

      // Determine country
      if (placeType.contains('country')) {
        country = placeName;
      } else {
        country = extractFromContext('country');
      }

      return PlaceDbModel(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        placeName: placeName?.isNotEmpty == true ? placeName : null,
        locality: locality?.isNotEmpty == true ? locality : null,
        country: country?.isNotEmpty == true ? country : null,
        address: address?.isNotEmpty == true ? address : null,
      );
    } catch (e) {
      AppLogger.error('SpMapTilerGeocodingService.reverseGeocode error: $e');
      return null;
    }
  }

  @override
  Future<List<PlaceDbModel>> searchPlaces(
    String query, {
    SpLatLng? proximity, // Optional proximity hint for better search results
    List<String>? countries,
  }) async {
    try {
      // MapTiler forward geocoding format: /{query}.json
      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json?key=$kMapTilerApiKey&limit=5&countries=${countries?.join(",")}',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        AppLogger.error(
          'SpMapTilerGeocodingService.searchPlaces API error: ${response.statusCode} - ${response.body}',
        );
        return [];
      }

      final data = jsonDecode(response.body);
      final features = data['features'] as List<dynamic>?;

      if (features == null || features.isEmpty) return [];

      return features.map((feature) {
        // MapTiler provides coordinates in a `center` array as [longitude, latitude]
        final center = feature['center'] as List<dynamic>?;
        final lng = (center != null && center.isNotEmpty) ? (center[0] as num).toDouble() : 0.0;
        final lat = (center != null && center.length > 1) ? (center[1] as num).toDouble() : 0.0;

        return PlaceDbModel(
          latitude: lat,
          longitude: lng,
          placeName: feature['text'],
          address: feature['place_name'],
          // We can leave locality and country null here, or parse the `context`
          // list again if your Search UI requires those fields immediately.
        );
      }).toList();
    } catch (e) {
      AppLogger.error('SpMapTilerGeocodingService.searchPlaces error: $e');
      return [];
    }
  }
}
