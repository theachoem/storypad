import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/widgets/maps/map_types.dart';

/// Returns the device's current or last-known location, or `null` when unavailable.
typedef DeviceLocationLoader = Future<SpLatLng?> Function();

/// Returns an ordered list of recent story locations (most recent first).
typedef StoryLocationsLoader = Future<List<SpLatLng>> Function();

enum InitialMapCameraSource {
  selectedPlace,
  devicePlace,
  storyLocation,
  fallback,
}

class InitialMapCameraResult {
  const InitialMapCameraResult({
    required this.camera,
    required this.source,
  });

  final SpMapCamera camera;
  final InitialMapCameraSource source;
}

/// Determines the best initial map camera from the available sources.
///
/// Fallback order (first non-null result wins):
///   1. [selectedPlace] — an existing picker place (e.g. story already has a location)
///   2. Device place — from [fetchDeviceLocation] (without prompting for permission)
///   3. Story locations — centroid of recent nearby journals from [fetchStoryLocations]
///   4. [fallbackCamera] — neutral world view at zoom 2
///
/// Example:
/// ```dart
/// final resolver = InitialMapCameraResolver(
///   fetchDeviceLocation: SpLocationService.fetchLastKnownLocation,
///   fetchStoryLocations: () async {
///     final stories = await StoryDbModel.db.getRecentStoriesWithLocation();
///     return stories.map((s) => s.location).toList();
///   },
/// );
/// final result = await resolver.resolve();
/// // result.source == InitialMapCameraSource.devicePlace
/// // result.camera.target == SpLatLng(11.5564, 104.9282)  (Phnom Penh)
/// ```
class InitialMapCameraResolver {
  const InitialMapCameraResolver({
    required this.fetchDeviceLocation,
    required this.fetchStoryLocations,
    this.preferDevicePlace = true,
  });

  static const SpMapCamera fallbackCamera = SpMapCamera(
    target: SpLatLng(0.0, 0.0),
    zoom: 2.0,
  );

  final DeviceLocationLoader fetchDeviceLocation;
  final StoryLocationsLoader fetchStoryLocations;
  final bool preferDevicePlace;

  Future<InitialMapCameraResult> resolve({PlaceDbModel? selectedPlace}) async {
    if (selectedPlace != null && _isValidPoint(selectedPlace.latLng)) {
      return InitialMapCameraResult(
        camera: SpMapCamera(target: selectedPlace.latLng, zoom: 15.0),
        source: InitialMapCameraSource.selectedPlace,
      );
    }

    final Future<InitialMapCameraResult?> deviceFuture = _resolveDevicePlace();
    final Future<InitialMapCameraResult?> storyFuture = _resolveStoryLocations();

    final InitialMapCameraResult? deviceResult = await deviceFuture;
    final InitialMapCameraResult? storyResult = await storyFuture;

    if (preferDevicePlace) {
      if (deviceResult != null) return deviceResult;
      if (storyResult != null) return storyResult;
    } else {
      if (storyResult != null) return storyResult;
      if (deviceResult != null) return deviceResult;
    }

    return const InitialMapCameraResult(
      camera: fallbackCamera,
      source: InitialMapCameraSource.fallback,
    );
  }

  Future<InitialMapCameraResult?> _resolveDevicePlace() async {
    final SpLatLng? location = await fetchDeviceLocation();
    if (location == null || !_isValidPoint(location)) return null;

    return InitialMapCameraResult(
      camera: SpMapCamera(target: location, zoom: 13.0),
      source: InitialMapCameraSource.devicePlace,
    );
  }

  Future<InitialMapCameraResult?> _resolveStoryLocations() async {
    final List<SpLatLng> locations = (await fetchStoryLocations()).where(_isValidPoint).toList();
    if (locations.isEmpty) return null;

    return InitialMapCameraResult(
      camera: _storyCameraFor(locations),
      source: InitialMapCameraSource.storyLocation,
    );
  }

  /// Picks a camera that best frames the given story [locations] (most recent first).
  ///
  /// - 1 location  → zoomed in (zoom 12)
  /// - tight cluster near the first point → averaged center, zoom derived from spread
  /// - scattered locations → falls back to the most recent point (zoom 12)
  static SpMapCamera _storyCameraFor(List<SpLatLng> locations) {
    if (locations.length == 1) {
      return SpMapCamera(target: locations.single, zoom: 12.0);
    }

    final SpLatLng anchor = locations.first;
    final List<SpLatLng> recentCluster = locations
        .take(20)
        .where((location) => _isNear(location, anchor, latitudeSpan: 0.8, longitudeSpan: 0.8))
        .toList();

    if (recentCluster.length < 2) {
      return SpMapCamera(target: anchor, zoom: 12.0);
    }

    final SpLatLng center = _average(recentCluster);
    final double latitudeSpan = _span(recentCluster.map((location) => location.latitude));
    final double longitudeSpan = _span(recentCluster.map((location) => location.longitude));
    final double maxSpan = latitudeSpan > longitudeSpan ? latitudeSpan : longitudeSpan;

    return SpMapCamera(
      target: center,
      zoom: _zoomForSpan(maxSpan),
    );
  }

  static SpLatLng _average(List<SpLatLng> locations) {
    double latitude = 0.0;
    double longitude = 0.0;

    for (final SpLatLng location in locations) {
      latitude += location.latitude;
      longitude += location.longitude;
    }

    return SpLatLng(latitude / locations.length, longitude / locations.length);
  }

  static double _span(Iterable<double> values) {
    double? min;
    double? max;

    for (final double value in values) {
      min = min == null || value < min ? value : min;
      max = max == null || value > max ? value : max;
    }

    if (min == null || max == null) return 0.0;
    return max - min;
  }

  /// Maps a degree span (max of lat/lon spread) to a zoom level.
  ///
  /// span ≤ 0.03° → 13.5 (city district)
  /// span ≤ 0.15° → 12.0 (city)
  /// span ≤ 0.45° → 10.5 (metro area)
  /// span  > 0.45° →  9.0 (region)
  static double _zoomForSpan(double span) {
    if (span <= 0.03) return 13.5;
    if (span <= 0.15) return 12.0;
    if (span <= 0.45) return 10.5;
    return 9.0;
  }

  static bool _isNear(
    SpLatLng location,
    SpLatLng anchor, {
    required double latitudeSpan,
    required double longitudeSpan,
  }) {
    return (location.latitude - anchor.latitude).abs() <= latitudeSpan &&
        (location.longitude - anchor.longitude).abs() <= longitudeSpan;
  }

  static bool _isValidPoint(SpLatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90.0 &&
        point.latitude <= 90.0 &&
        point.longitude >= -180.0 &&
        point.longitude <= 180.0;
  }
}
