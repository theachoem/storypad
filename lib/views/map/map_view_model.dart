import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_map_controller.dart';
import 'map_view.dart';
import 'local_widgets/maps/map_types.dart';

class MapViewModel extends ChangeNotifier with DisposeAwareMixin {
  static const int visibleStoryLimit = 100;
  static const double _minViewportFetchExpansionFactor = 1.15;
  static const double _maxViewportFetchExpansionFactor = 2.2;
  static const double _minExpansionZoom = 4.0;
  static const double _maxExpansionZoom = 16.0;

  final MapRoute params;
  final BuildContext viewContext;

  MapViewModel({
    required this.params,
    required this.viewContext,
  });

  SpMapCamera get initialSpMapCamera => const SpMapCamera(
    target: SpLatLng(37.7815, -122.4310),
    zoom: 10.8,
  );

  SpMapRenderer get mapRenderer => SpMapRenderer.googleMaps;

  final SpMapController mapController = SpMapController();

  Future<void> goToCurrentLocation() async {
    final place = await SpLocationService.fetchCurrentPlace();
    if (place == null) return;

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

  SpMapStyle _mapStyle = SpMapStyle.streets;
  SpMapStyle get mapStyle => _mapStyle;

  List<MapStoryObject> _visibleStories = [];
  List<MapStoryObject> get visibleStories => _visibleStories;
  List<MapStoryObject> _fetchedStories = [];
  SpLatLngBounds? _fetchedBounds;
  final Map<int, File?> _assetFileById = {};
  final Map<int, Future<File?>> _assetFileFutureById = {};

  List<SpMapMarker<MapStoryObject>> get mapMarkers {
    return visibleStories
        .map(
          (story) => SpMapMarker<MapStoryObject>(
            id: story.id.toString(),
            point: story.location,
            data: story,
            title: DateFormatHelper.yMEd_Hm(story.storyDate, Localizations.localeOf(viewContext)),
            size: const Size(62.0, 74.0),
            alignment: Alignment.topCenter,
            anchor: const Offset(0.5, 1.0),
          ),
        )
        .toList();
  }

  int _loadVersion = 0;

  Future<void> handleViewportChanged(SpMapViewport viewport) async {
    final int loadVersion = ++_loadVersion;
    final fetchBounds = viewport.bounds.expanded(_viewportFetchExpansionFactor(viewport.zoom));

    if (_fetchedBounds?.containsBounds(viewport.bounds) != true) {
      final stories = await StoryDbModel.db.getStoriesWithLocation(bounds: fetchBounds);
      if (disposed || loadVersion != _loadVersion) return;

      _fetchedStories = stories;
      _fetchedBounds = fetchBounds;
    }

    final visibleStories = _limitStoriesByDistance(_fetchedStories, viewport.center);
    if (_hasSameStoryIds(_visibleStories, visibleStories)) return;

    _visibleStories = visibleStories;
    notifyListeners();
    unawaited(_cacheFirstAssetFiles(visibleStories));
  }

  File? firstAssetFileForStory(MapStoryObject story) {
    final int? assetId = _firstAssetId(story);
    if (assetId == null) return null;
    return _assetFileById[assetId];
  }

  Color markerColorForStory(MapStoryObject story) {
    return kColorsByDayLight[story.storyDate.weekday]!;
  }

  Future<void> _cacheFirstAssetFiles(List<MapStoryObject> stories) async {
    final List<int> uncachedAssetIds = stories
        .map(_firstAssetId)
        .whereType<int>()
        .where((assetId) => !_assetFileById.containsKey(assetId) && !_assetFileFutureById.containsKey(assetId))
        .toList();

    if (uncachedAssetIds.isEmpty) return;

    bool changed = false;
    await Future.wait(
      uncachedAssetIds.map((assetId) async {
        final future = _loadAssetFile(assetId);
        _assetFileFutureById[assetId] = future;

        try {
          final file = await future;
          if (_assetFileById[assetId]?.path != file?.path || (_assetFileById[assetId] == null && file != null)) {
            _assetFileById[assetId] = file;
            changed = true;
          } else {
            _assetFileById.putIfAbsent(assetId, () => file);
          }
        } finally {
          _assetFileFutureById.remove(assetId);
        }
      }),
    );

    if (!disposed && changed) {
      notifyListeners();
    }
  }

  Future<File?> _loadAssetFile(int assetId) async {
    final asset = await AssetDbModel.db.find(assetId);
    return asset?.localFile;
  }

  int? _firstAssetId(MapStoryObject story) {
    final assets = story.assets;
    if (assets == null || assets.isEmpty) return null;
    return assets.first;
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
  }
}
