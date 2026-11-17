import 'dart:math' as math;

/// Platform-agnostic latitude/longitude coordinate.
///
/// Keeps the [MapAdapter] interface free from package-specific types like
/// `google_maps_flutter`'s `LatLng` or `latlong2`'s `LatLng`.
class SpLatLng {
  const SpLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Great-circle distance in meters (haversine).
  double distanceTo(SpLatLng other) {
    const double earthRadius = 6371000.0;
    double rad(double degrees) => degrees * math.pi / 180.0;

    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    // Clamped: rounding can push it just past 1 for antipodal points, and sqrt(1 - a) would be NaN.
    final a =
        (math.pow(math.sin(dLat / 2), 2) +
                math.cos(rad(latitude)) * math.cos(rad(other.latitude)) * math.pow(math.sin(dLng / 2), 2))
            .clamp(0.0, 1.0);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  String toString() => 'SpLatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) => other is SpLatLng && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
