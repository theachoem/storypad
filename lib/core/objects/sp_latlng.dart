/// Platform-agnostic latitude/longitude coordinate.
///
/// Keeps the [MapAdapter] interface free from package-specific types like
/// `google_maps_flutter`'s `LatLng` or `latlong2`'s `LatLng`.
class SpLatLng {
  const SpLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  String toString() => 'SpLatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) => other is SpLatLng && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
