import 'package:geolocator/geolocator.dart';
import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/geocoding/sp_place_result.dart';

class SpLocationService {
  const SpLocationService._();

  /// Requests permission (if needed), gets the device GPS position,
  /// and reverse-geocodes it into a [SpPlaceResult].
  ///
  /// Returns `null` when permission is denied, GPS is unavailable,
  /// or an error occurs.
  static Future<SpPlaceResult?> fetchCurrentPlace() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final latLng = SpLatLng(position.latitude, position.longitude);
      return await SpGeocodingService.instance.reverseGeocode(latLng) ??
          SpPlaceResult(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
