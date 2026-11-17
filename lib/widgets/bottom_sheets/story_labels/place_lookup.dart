part of '../sp_story_labels_sheet.dart';

/// The Map tab's lookups. No state: the tab keeps only what's on screen.
class _PlaceLookup {
  const _PlaceLookup._();

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

  /// [place] with its details looked up — shared with the story, so a spot it's still looking up (e.g. one
  /// just set from the current location) is joined, not looked up again (see [PlaceDetailsService]).
  static Future<PlaceDbModel?> details(PlaceDbModel place) => PlaceDetailsService.details(place);

  /// The current location, only when access is already granted — never asks or shows a dialog.
  static Future<PlaceDbModel?> currentPlaceIfAllowed() async {
    final result = await SpLocationService.fetchCurrentPlace(requestPermission: false);
    return result.isSuccess ? result.place : null;
  }

  /// Places from past stories in [bounds]: a hint of where the user has been, so they can drag to
  /// (or tap) one. One per spot (~11m), at most 500.
  static Future<List<SpLatLng>> savedPlaceSpots(SpLatLngBounds bounds) async {
    final stories = await StoryDbModel.db.getStoriesWithLocation(bounds: bounds, limit: 500);
    return {for (final story in stories) PlaceDetailsService.spotKey(story.location): story.location}.values.toList();
  }

  /// [spot] as a dot for [style]. Coordinates only: tapping a dot picks its exact spot, and the
  /// details are looked up after.
  static SpMapMarker<PlaceDbModel> dot(SpLatLng spot, SpMapStyle style) {
    return SpMapMarker<PlaceDbModel>(
      id: PlaceDetailsService.spotKey(spot),
      point: spot,
      data: PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude),
      clusterable: false,
      size: const Size.square(SpMapDotMarker.size),
      iconCacheKey: SpMapDotMarker.iconCacheKeyFor(style),
    );
  }

  /// The story's place, pinned to its spot (view mode).
  static SpMapMarker<PlaceDbModel> placePin(PlaceDbModel place) {
    return SpMapMarker<PlaceDbModel>(
      id: SpMapPlacePin.iconCacheKey,
      point: place.latLng,
      data: place,
      clusterable: false,
      size: SpMapPlacePin.size,
      iconCacheKey: SpMapPlacePin.iconCacheKey,
    );
  }
}
