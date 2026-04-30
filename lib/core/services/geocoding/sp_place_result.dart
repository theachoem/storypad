import 'package:storypad/core/map/sp_latlng.dart';

/// The result returned by [SpGeocodingService].
///
/// Field names align with [PlaceDbModel] so results can be applied directly
/// without mapping.
class SpPlaceResult {
  const SpPlaceResult({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.locality,
    this.country,
    this.address,
  });

  final double latitude;
  final double longitude;

  /// Human-readable place name, e.g. "Knowledge Cafe".
  final String? placeName;

  /// City / locality, e.g. "Phnom Penh".
  final String? locality;

  /// Country name, e.g. "Cambodia".
  final String? country;

  /// Full formatted address string.
  final String? address;

  SpLatLng get latLng => SpLatLng(latitude, longitude);

  /// Display label: placeName if available, otherwise locality, otherwise coordinates.
  String get displayLabel {
    if (placeName != null && placeName!.isNotEmpty) return placeName!;
    if (locality != null && locality!.isNotEmpty) return locality!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  @override
  String toString() => 'SpPlaceResult(lat=$latitude, lon=$longitude, place=$placeName, locality=$locality)';
}
