part of '../sp_story_labels_sheet.dart';

/// The Map tab's lookups. No state: the tab keeps only what's on screen.
class _PlaceLookup {
  const _PlaceLookup._();

  // A hung geocoder must not keep Save disabled.
  static const Duration _detailsTimeout = Duration(seconds: 10);

  /// Where the map starts: the saved place, else the device's last known location or recent
  /// story places — and whether that's the device's location (to show its dot).
  static Future<({SpMapCamera camera, bool fromDevice})> initialCamera(PlaceDbModel? savedPlace) async {
    final resolver = InitialMapCameraResolver(
      fetchDeviceLocation: SpLocationService.fetchLastKnownLocation,
      fetchStoryLocations: () async {
        final stories = await StoryDbModel.db.getRecentStoriesWithLocation(limit: 20);
        return stories.map((story) => story.location).toList();
      },
      // Choosing one precise place: start close enough to read place names.
      closeZoomBoost: 4.0,
    );

    final result = await resolver.resolve(selectedPlace: savedPlace);
    return (camera: result.camera, fromDevice: result.source == InitialMapCameraSource.devicePlace);
  }

  /// [place] with its details looked up (see [PlaceSelectionService.mergeDetails]): the user's own
  /// name for a place within ~30m (from their stories), and the geocoder's. Null if nothing's found.
  static Future<PlaceDbModel?> details(PlaceDbModel place) async {
    final (saved, geocoded) = await (
      SpGeocodingService.reverseGeocodeViaDb(place.latLng, namedOnly: true).catchError((_) => null),
      SpGeocodingService.systemInstance.reverseGeocode(place.latLng).timeout(_detailsTimeout, onTimeout: () => null),
    ).wait;
    return PlaceSelectionService.mergeDetails(place, saved: saved, geocoded: geocoded);
  }

  /// The current location, only when access is already granted — never asks or shows a dialog.
  static Future<PlaceDbModel?> currentPlaceIfAllowed() async {
    final result = await SpLocationService.fetchCurrentPlace(requestPermission: false);
    return result.isSuccess ? result.place : null;
  }

  /// Places from past stories in [bounds]: a hint of where the user has been, so they can drag to
  /// (or tap) one. One per spot (~11m), at most 500.
  static Future<List<SpLatLng>> savedPlaceSpots(SpLatLngBounds bounds) async {
    final stories = await StoryDbModel.db.getStoriesWithLocation(bounds: bounds, limit: 500);
    return {for (final story in stories) _spotId(story.location): story.location}.values.toList();
  }

  /// [spot] as a dot for [style]. Coordinates only: tapping a dot picks its exact spot, and the
  /// details are looked up after.
  static SpMapMarker<PlaceDbModel> dot(SpLatLng spot, SpMapStyle style) {
    return SpMapMarker<PlaceDbModel>(
      id: _spotId(spot),
      point: spot,
      data: PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude),
      clusterable: false,
      size: const Size.square(SpMapDotMarker.size),
      iconCacheKey: SpMapDotMarker.iconCacheKeyFor(style),
    );
  }

  static String _spotId(SpLatLng spot) => '${spot.latitude.toStringAsFixed(4)},${spot.longitude.toStringAsFixed(4)}';
}
