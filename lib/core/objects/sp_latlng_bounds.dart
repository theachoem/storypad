import 'package:storypad/core/objects/sp_latlng.dart';

class SpLatLngBounds {
  const SpLatLngBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  SpLatLng get center => SpLatLng(
    (south + north) / 2,
    (west + east) / 2,
  );

  bool contains(SpLatLng point) {
    return point.latitude >= south && point.latitude <= north && point.longitude >= west && point.longitude <= east;
  }

  bool containsBounds(SpLatLngBounds other) {
    return contains(SpLatLng(other.south, other.west)) && contains(SpLatLng(other.north, other.east));
  }

  SpLatLngBounds expanded(double factor) {
    if (factor <= 1.0) return this;

    final double latitudeSpan = north - south;
    final double longitudeSpan = east - west;
    final double latitudePadding = latitudeSpan * (factor - 1.0) / 2;
    final double longitudePadding = longitudeSpan * (factor - 1.0) / 2;

    return SpLatLngBounds(
      south: (south - latitudePadding).clamp(-90.0, 90.0),
      west: (west - longitudePadding).clamp(-180.0, 180.0),
      north: (north + latitudePadding).clamp(-90.0, 90.0),
      east: (east + longitudePadding).clamp(-180.0, 180.0),
    );
  }
}
