import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/assets/backup_asset_downloader_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/location/sp_app_location_service.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/map/initial_map_camera_resolver.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_stories_bottom_sheet.dart';
import 'package:storypad/widgets/maps/sp_map_controller.dart';
import 'package:storypad/views/map/map_view.dart';
import 'package:storypad/widgets/maps/map_types.dart';

class MapViewModel extends ChangeNotifier with DisposeAwareMixin {
  static const int visibleStoryLimit = 100;
  static const double _minViewportFetchExpansionFactor = 1.15;
  static const double _maxViewportFetchExpansionFactor = 2.2;
  static const double _minExpansionZoom = 4.0;
  static const double _maxExpansionZoom = 16.0;
  static const double _storiesSheetMapFocusOffsetFactor = 0.18;
  static const int _imageResolveConcurrency = 3;

  final MapRoute params;
  final BuildContext viewContext;

  MapViewModel({
    required this.params,
    required this.viewContext,
  }) {
    unawaited(resolveInitialCamera());
    StoryDbModel.db.addGlobalListener(_reloadVisibleStories);
  }

  SpMapCamera _initialSpMapCamera = InitialMapCameraResolver.fallbackCamera;
  SpMapCamera get initialSpMapCamera => _initialSpMapCamera;

  bool _isCameraResolved = false;
  bool get isCameraResolved => _isCameraResolved;

  bool _showCurrentLocation = false;
  bool get showCurrentLocation => _showCurrentLocation;

  SpMapRenderer get mapRenderer => viewContext.read<DevicePreferencesProvider>().mapRenderer;

  final SpMapController mapController = SpMapController();

  @override
  void dispose() {
    StoryDbModel.db.removeGlobalListener(_reloadVisibleStories);
    _imageResolveDebounce?.cancel();
    _notifyDebounce?.cancel();
    super.dispose();
  }

  /// Refreshes visible pins after a story's place or photos change elsewhere
  /// (e.g. edited from the story detail sheet). Bottom sheet story lists
  /// already know how to refresh themselves; this only concerns the map's
  /// own pins and pin images.
  ///
  /// The global listener carries no record id, so which story changed is
  /// unknown here — clear the per-story image cache entirely rather than
  /// leaving a stale pin photo behind for the one that did.
  Future<void> _reloadVisibleStories() async {
    if (_lastViewport == null) return;
    _imageAssetIdByStoryId.clear();
    // Not awaited: this runs as a DB global listener inside afterCommit, and
    // awaiting the full viewport reload here would make every story write
    // block on map refresh/image-download work.
    unawaited(handleViewportChanged(_lastViewport!, forceReload: true));
  }

  Future<void> resolveInitialCamera() async {
    final resolver = InitialMapCameraResolver(
      fetchDeviceLocation: SpLocationService.fetchLastKnownLocation,
      fetchStoryLocations: () async {
        final stories = await StoryDbModel.db.getRecentStoriesWithLocation(limit: 20);
        return stories.map((story) => story.location).toList();
      },
    );

    final result = await resolver.resolve();
    if (disposed) return;

    _initialSpMapCamera = result.camera;
    _isCameraResolved = true;

    if (result.source == InitialMapCameraSource.devicePlace) {
      _showCurrentLocation = true;
    }

    notifyListeners();
  }

  Future<void> goToCurrentLocation(BuildContext context) async {
    final place = await SpAppLocationService.fetchCurrentPlaceWithRecovery(context, skipReverseGeocoding: true);
    if (!context.mounted || place == null) return;

    _showCurrentLocation = true;
    notifyListeners();

    await mapController.animateTo(
      place.latitude,
      place.longitude,
      zoom: 15.0,
      bearing: 0.0,
    );
  }

  Future<void> resetRotation() async {
    await mapController.resetRotation();
  }

  late SpMapStyle _mapStyle = viewContext.read<DevicePreferencesProvider>().preferences.mapStyle;
  SpMapStyle get mapStyle => _mapStyle;

  List<MapStoryObject> _visibleStories = [];
  List<MapStoryObject> get visibleStories => _visibleStories;
  List<MapStoryObject> _fetchedStories = [];
  SpLatLngBounds? _fetchedBounds;

  final Map<int, File?> _assetFileById = {};
  final Map<int, Future<File?>> _assetFileFutureById = {};

  /// Story id → the asset that supplies its pin image, or null when it has
  /// none. Absent means "not looked up yet", which is why this is a map and
  /// not a nullable field.
  final Map<int, int?> _imageAssetIdByStoryId = {};
  final Set<int> _failedAssetIds = {};

  Timer? _imageResolveDebounce;
  Timer? _notifyDebounce;

  List<SpMapMarker<MapStoryObject>> get mapMarkers {
    return visibleStories
        .map(
          (story) => SpMapMarker<MapStoryObject>(
            id: story.id.toString(),
            point: story.location,
            data: story,
            size: const Size.square(60.0),
            anchor: const Offset(0.5, 1.0),
            iconCacheKey: _iconCacheKeyForStory(story),
          ),
        )
        .toList();
  }

  /// What the pin will *look* like, so identical pins share a bitmap.
  ///
  /// With a photo the marker is the photo under a fixed scrim and the weekday
  /// colour never shows, so it stays out of the key — otherwise every photo
  /// pin would be redrawn on a light/dark switch for no visible change.
  /// Without one, the pin is nothing but that colour, and all of them collapse
  /// onto the seven weekday bitmaps.
  String _iconCacheKeyForStory(MapStoryObject story) {
    final int? assetId = _firstImageAssetId(story);
    if (assetId != null && _assetFileById[assetId] != null) return 'img:$assetId';

    return 'plc:${markerColorForStory(story).toARGB32()}';
  }

  int _loadVersion = 0;
  SpMapViewport? _lastViewport;

  Future<void> handleViewportChanged(
    SpMapViewport viewport, {
    bool forceReload = false,
  }) async {
    _lastViewport = viewport;
    final int loadVersion = ++_loadVersion;
    final fetchBounds = viewport.bounds.expanded(_viewportFetchExpansionFactor(viewport.zoom));

    if (_fetchedBounds?.containsBounds(viewport.bounds) != true || forceReload) {
      AppLogger.d('$runtimeType#handleViewportChanged - fetching stories for bounds: $fetchBounds');

      final stories = await StoryDbModel.db.getStoriesWithLocation(bounds: fetchBounds);
      if (disposed || loadVersion != _loadVersion) return;

      _fetchedStories = stories;
      _fetchedBounds = fetchBounds;
    }

    final visibleStories = _limitStoriesByDistance(_fetchedStories, viewport.center);
    // Same ids can still mean different pins when forced: forceReload is what
    // a story edit (place, photos) triggers, and that never changes which
    // stories are visible, only what their pins should look like.
    if (!forceReload && _hasSameStoryIds(_visibleStories, visibleStories)) return;

    // Before publishing, not after: a pin drawn now and given its photo later
    // has to visibly change twice. Only new stories cost anything here, and
    // the first paint is already waiting on far slower bitmap rendering.
    await _resolveLocalImages(visibleStories);
    if (disposed || loadVersion != _loadVersion) return;

    _visibleStories = visibleStories;
    notifyListeners();
    _scheduleImageDownloads(visibleStories);
  }

  /// Waits for the camera to settle before going near the network. Downloading
  /// mid-drag competes with the gesture for exactly the frames it needs; the
  /// pins fill in a moment later either way.
  void _scheduleImageDownloads(List<MapStoryObject> stories) {
    _imageResolveDebounce?.cancel();
    _imageResolveDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_downloadMissingImages(stories));
    });
  }

  File? firstAssetFileForStory(MapStoryObject story) {
    final int? assetId = _firstImageAssetId(story);
    if (assetId == null) return null;
    return _assetFileById[assetId];
  }

  Color markerColorForStory(MapStoryObject story) {
    return ColorFromDayService(context: viewContext).get(story.storyDate.weekday)!;
  }

  Future<void> onMarkerTap(SpMapMarker<MapStoryObject> marker) async {
    await _showStoriesSheet(
      [marker.data.id],
      focusPoint: marker.point,
    );
  }

  Future<void> onClusterTap(List<SpMapMarker<MapStoryObject>> markers) async {
    final List<int> storyIds = markers.map((marker) => marker.data.id).toSet().toList();
    await _showStoriesSheet(storyIds, focusPoint: _clusterCenter(markers));
  }

  Future<void> _showStoriesSheet(
    List<int> storyIds, {
    SpLatLng? focusPoint,
  }) async {
    if (storyIds.isEmpty || disposed) return;
    if (!viewContext.mounted) return;

    final filter = SearchFilterObject(years: {}, types: {}, assetId: null, storyIds: storyIds.toSet());

    // Use view context to show bottom sheet to avoid using override theme of map overlay for sheet.
    SpStoriesBottomSheet(
      filter: filter,

      // Only show map opener button when there's exactly 1 story.
      // We want to open extact position, not cluster center.
      storyLocation: storyIds.length == 1 ? focusPoint : null,
    ).show(context: viewContext);

    if (focusPoint != null) {
      Future.delayed(const Duration(milliseconds: 300));
      if (disposed) return;
      await _focusPointAboveStoriesSheet(focusPoint);
    }
  }

  Future<void> _focusPointAboveStoriesSheet(SpLatLng point) async {
    final SpMapViewport? viewport = _lastViewport;
    if (viewport == null) return;

    final double latitudeSpan = viewport.bounds.north - viewport.bounds.south;
    if (!latitudeSpan.isFinite || latitudeSpan <= 0) return;

    final double adjustedLatitude = (point.latitude - (latitudeSpan * _storiesSheetMapFocusOffsetFactor)).clamp(
      -90.0,
      90.0,
    );

    await mapController.animateTo(
      adjustedLatitude,
      point.longitude,
      zoom: viewport.zoom,
    );
  }

  SpLatLng _clusterCenter(List<SpMapMarker<MapStoryObject>> markers) {
    if (markers.isEmpty) return _lastViewport?.center ?? initialSpMapCamera.target;

    double minLatitude = markers.first.point.latitude;
    double maxLatitude = markers.first.point.latitude;
    double minLongitude = markers.first.point.longitude;
    double maxLongitude = markers.first.point.longitude;

    for (final marker in markers.skip(1)) {
      minLatitude = minLatitude < marker.point.latitude ? minLatitude : marker.point.latitude;
      maxLatitude = maxLatitude > marker.point.latitude ? maxLatitude : marker.point.latitude;
      minLongitude = minLongitude < marker.point.longitude ? minLongitude : marker.point.longitude;
      maxLongitude = maxLongitude > marker.point.longitude ? maxLongitude : marker.point.longitude;
    }

    return SpLatLng(
      (minLatitude + maxLatitude) / 2,
      (minLongitude + maxLongitude) / 2,
    );
  }

  /// Works out which asset gives each story its pin, and whether it's already
  /// on disk. Database and filesystem only — never the network, because this
  /// runs before the first paint.
  ///
  /// [MapStoryObject.assets] is bare ids with no type, so the first one can
  /// just as easily be a voice note or a video — which the pin can't draw, and
  /// which downloading would be a waste of megabytes. A single query answers
  /// both "which asset is the image" and "is it downloaded" for the whole
  /// visible set.
  Future<void> _resolveLocalImages(List<MapStoryObject> stories) async {
    final List<MapStoryObject> unresolved = stories
        .where((story) => !_imageAssetIdByStoryId.containsKey(story.id))
        .toList();
    if (unresolved.isEmpty) return;

    final List<int> candidateIds = unresolved.expand((story) => story.assets ?? const <int>[]).toList();

    Map<int, AssetDbModel> imageAssetsById = const {};
    if (candidateIds.isNotEmpty) {
      final collection = await AssetDbModel.db.where(
        filters: {"ids": candidateIds, "type": AssetType.image},
      );
      if (disposed) return;

      imageAssetsById = {for (final asset in collection?.items ?? const <AssetDbModel>[]) asset.id: asset};
    }

    for (final MapStoryObject story in unresolved) {
      AssetDbModel? firstImageAsset;
      for (final int assetId in story.assets ?? const <int>[]) {
        final AssetDbModel? asset = imageAssetsById[assetId];
        if (asset != null) {
          firstImageAsset = asset;
          break;
        }
      }

      _imageAssetIdByStoryId[story.id] = firstImageAsset?.id;

      // A null value means "this story has no image" — _downloadMissingImages
      // filters those out and instead looks for a non-null asset id whose
      // entry in _assetFileById is still null. Absent means never resolved.
      if (firstImageAsset != null) {
        _assetFileById.putIfAbsent(firstImageAsset.id, () => firstImageAsset!.localFile);
      }
    }
  }

  Future<void> _downloadMissingImages(List<MapStoryObject> stories) async {
    if (!viewContext.mounted) return;

    // Read once up front: the downloads below are awaited, and reaching back
    // into the context after that is exactly what `use_build_context_
    // synchronously` is warning about.
    final List<BackupCloudService> signedInServices = viewContext.read<BackupProvider>().signedInServices;
    if (signedInServices.isEmpty) return;

    final List<int> pendingAssetIds = stories
        .map(_firstImageAssetId)
        .whereType<int>()
        .where(
          (assetId) =>
              _assetFileById[assetId] == null &&
              !_assetFileFutureById.containsKey(assetId) &&
              !_failedAssetIds.contains(assetId),
        )
        .toList();

    if (pendingAssetIds.isEmpty) return;

    // A few at a time: a hundred visible pins would otherwise open a hundred
    // connections at once.
    for (int start = 0; start < pendingAssetIds.length; start += _imageResolveConcurrency) {
      if (disposed) return;

      final Iterable<int> chunk = pendingAssetIds.skip(start).take(_imageResolveConcurrency);
      await Future.wait(chunk.map((assetId) => _resolveAssetFile(assetId, signedInServices)));
    }
  }

  Future<void> _resolveAssetFile(int assetId, List<BackupCloudService> signedInServices) async {
    final Future<File?> future = _loadAssetFile(assetId, signedInServices);
    _assetFileFutureById[assetId] = future;

    try {
      final File? file = await future;
      if (disposed) return;

      _assetFileById[assetId] = file;
      // Each arrival changes one pin's cache key, and every notify rebuilds
      // the whole marker list — so let a burst settle into one rebuild.
      if (file != null) _notifyListenersCoalesced();
    } finally {
      _assetFileFutureById.remove(assetId);
    }
  }

  /// The download path. Only reached for images [_resolveLocalImages] found
  /// no local file for, so the `localFile` check below is a race guard for a
  /// copy that arrived from another screen in the meantime.
  Future<File?> _loadAssetFile(int assetId, List<BackupCloudService> signedInServices) async {
    final AssetDbModel? asset = await AssetDbModel.db.find(assetId);
    if (asset == null || disposed) return null;

    final File? localFile = asset.localFile;
    if (localFile != null) return localFile;

    // One failure per asset is enough. Without this, a failed download leaves
    // the id uncached, and every viewport change queues the same doomed
    // request again.
    if (_failedAssetIds.contains(assetId)) return null;
    if (signedInServices.isEmpty) return null;

    try {
      final String localFilePath = await BackupAssetDownloaderService().downloadAsset(
        asset: asset,
        signedInServices: signedInServices,
      );
      return File(localFilePath);
    } catch (e) {
      _failedAssetIds.add(assetId);
      AppLogger.d('$runtimeType#_loadAssetFile failed to download asset $assetId: $e');
      return null;
    }
  }

  int? _firstImageAssetId(MapStoryObject story) => _imageAssetIdByStoryId[story.id];

  void _notifyListenersCoalesced() {
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 150), notifyListeners);
  }

  double _viewportFetchExpansionFactor(double zoom) {
    final double clampedZoom = zoom.clamp(_minExpansionZoom, _maxExpansionZoom);
    final double progress = (clampedZoom - _minExpansionZoom) / (_maxExpansionZoom - _minExpansionZoom);
    return _minViewportFetchExpansionFactor +
        ((_maxViewportFetchExpansionFactor - _minViewportFetchExpansionFactor) * progress);
  }

  List<MapStoryObject> _limitStoriesByDistance(List<MapStoryObject> stories, SpLatLng center) {
    if (stories.length <= visibleStoryLimit) return stories;

    final sorted = [...stories]
      ..sort((a, b) {
        return _distanceSquared(a.location, center).compareTo(_distanceSquared(b.location, center));
      });

    return sorted.take(visibleStoryLimit).toList();
  }

  double _distanceSquared(SpLatLng a, SpLatLng b) {
    final double latitudeDelta = a.latitude - b.latitude;
    final double longitudeDelta = a.longitude - b.longitude;
    return latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta;
  }

  bool _hasSameStoryIds(List<MapStoryObject> current, List<MapStoryObject> next) {
    if (current.length != next.length) return false;

    for (int i = 0; i < current.length; i++) {
      if (current[i].id != next[i].id) return false;
    }

    return true;
  }

  void setMapStyle(SpMapStyle mapStyle) {
    if (_mapStyle == mapStyle) return;

    _mapStyle = mapStyle;
    notifyListeners();

    if (viewContext.mounted) {
      viewContext.read<DevicePreferencesProvider>().updateMapStyle(mapStyle);
    }
  }

  Future<void> goToNewPage() async {
    final addedStory = await EditStoryRoute(id: null, autoRequestLocation: true).push(viewContext);
    if (addedStory != null && addedStory is StoryDbModel) {
      if (addedStory.place != null && _lastViewport != null) {
        await handleViewportChanged(_lastViewport!, forceReload: true);
        await mapController.animateTo(
          addedStory.place!.latitude,
          addedStory.place!.longitude,
          zoom: 15.0,
          bearing: 0.0,
        );
      }
      Future.delayed(const Duration(seconds: 1)).then((_) {
        HomeView.reload(debugSource: '$runtimeType#goToNewPage');
      });
    }
  }
}
