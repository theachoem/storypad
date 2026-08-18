import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/maps/sp_map_controller.dart';

typedef SpGoogleMapMarkerIconBuilder<T> =
    Future<BitmapDescriptor> Function(
      BuildContext context,
      SpMapMarker<T> marker,
      double pixelRatio,
    );

class SpGoogleMap<T> extends StatefulWidget {
  const SpGoogleMap({
    super.key,
    required this.mapController,
    required this.initialCamera,
    required this.mapStyle,
    required this.markers,
    this.padding = EdgeInsets.zero,
    this.onMapTap,
    this.onMarkerTap,
    this.onClusterTap,
    this.markerIconBuilder,
    this.onViewportChanged,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.showCurrentLocation = false,
  });

  final SpMapController mapController;
  final SpMapCamera initialCamera;
  final EdgeInsets padding;
  final SpMapStyle mapStyle;
  final List<SpMapMarker<T>> markers;
  final ValueChanged<SpLatLng>? onMapTap;
  final ValueChanged<SpMapMarker<T>>? onMarkerTap;
  final ValueChanged<List<SpMapMarker<T>>>? onClusterTap;
  final SpGoogleMapMarkerIconBuilder<T>? markerIconBuilder;
  final SpMapViewportChanged? onViewportChanged;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<SpLatLng>? onCameraIdle;
  final bool showCurrentLocation;

  @override
  State<SpGoogleMap<T>> createState() => _SpGoogleMapState<T>();
}

class _SpGoogleMapState<T> extends State<SpGoogleMap<T>> with DebounchedCallback {
  // Cluster only show when there are at least 4 markers.
  static const ClusterManagerId _clusterManagerId = ClusterManagerId('sp_map_markers');

  /// How many freshly drawn icons to accumulate before pushing them to the
  /// map, trading a few extra rebuilds for pins that appear progressively.
  static const int _emitMarkersBatchSize = 5;

  static const int _maxCachedIcons = 300;

  late final Map<ClusterManagerId, ClusterManager> _clusterManagers;

  GoogleMapController? _googleMapController;
  late LatLng _currentCenter;
  double _currentZoom = 10.8;
  double _currentBearing = 0.0;
  double? _preparedPixelRatio;
  String? _preparedMarkerSignature;
  int _prepareVersion = 0;
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};

  /// Drawn icons keyed by [SpMapMarker.iconCacheKey] — by appearance, not by
  /// marker, so panning back over a pin reuses its bitmap and identical
  /// placeholder pins share one.
  final Map<String, BitmapDescriptor> _iconByCacheKey = <String, BitmapDescriptor>{};

  /// What each pin is showing *right now*, keyed by marker. Answers a
  /// different question from [_iconByCacheKey]: when a pin's appearance
  /// changes (its photo finished loading) the new bitmap isn't drawn yet, and
  /// without something to fall back on the pin would blink off the map until
  /// it is. Holding the old one keeps the swap to a single visible change.
  final Map<String, BitmapDescriptor> _displayedIconByMarkerId = <String, BitmapDescriptor>{};

  @override
  void initState() {
    super.initState();

    _currentCenter = _toLatLng(widget.initialCamera.target);
    _currentZoom = widget.initialCamera.zoom;

    _clusterManagers = <ClusterManagerId, ClusterManager>{
      _clusterManagerId: ClusterManager(
        clusterManagerId: _clusterManagerId,
        onClusterTap: _handleClusterTap,
      ),
    };
    _attachMapController();
  }

  @override
  void didUpdateWidget(SpGoogleMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.detach();
      _attachMapController();
    }
    final bool markerIconBuilderModeChanged =
        (oldWidget.markerIconBuilder == null) != (widget.markerIconBuilder == null);
    if (oldWidget.markers != widget.markers || markerIconBuilderModeChanged) {
      _prepareMarkerIconsIfNeeded(force: markerIconBuilderModeChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareMarkerIconsIfNeeded();
  }

  @override
  void dispose() {
    widget.mapController.detach();
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      padding: widget.padding,
      mapType: _toGoogleMapType(widget.mapStyle),
      initialCameraPosition: CameraPosition(
        target: _toLatLng(widget.initialCamera.target),
        zoom: widget.initialCamera.zoom,
      ),
      markers: Set<Marker>.of(_markers.values),
      clusterManagers: Set<ClusterManager>.of(_clusterManagers.values),
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: widget.showCurrentLocation,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _googleMapController = controller;
        unawaited(_notifyViewportChanged());
      },
      onTap: widget.onMapTap == null
          ? null
          : (LatLng latLng) {
              widget.onMapTap!(SpLatLng(latLng.latitude, latLng.longitude));
            },
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraIdle: widget.onCameraIdle == null
          ? null
          : () {
              widget.onCameraIdle!(SpLatLng(_currentCenter.latitude, _currentCenter.longitude));
            },
      onCameraMove: (CameraPosition position) {
        _currentCenter = position.target;
        _currentZoom = position.zoom;
        _currentBearing = position.bearing;

        if (!mounted) return;

        debouncedCallback(() {
          _notifyViewportChanged();
        }, duration: const Duration(milliseconds: 50));
      },
    );
  }

  Future<void> _notifyViewportChanged() async {
    final GoogleMapController? controller = _googleMapController;
    final SpMapViewportChanged? onViewportChanged = widget.onViewportChanged;
    if (controller == null || onViewportChanged == null) return;

    try {
      final LatLngBounds visibleRegion = await controller.getVisibleRegion();
      if (!mounted) return;

      onViewportChanged(
        SpMapViewport(
          bounds: SpLatLngBounds(
            south: visibleRegion.southwest.latitude,
            west: visibleRegion.southwest.longitude,
            north: visibleRegion.northeast.latitude,
            east: visibleRegion.northeast.longitude,
          ),
          center: SpLatLng(_currentCenter.latitude, _currentCenter.longitude),
          zoom: _currentZoom,
        ),
      );
    } catch (_) {}
  }

  void _attachMapController() {
    widget.mapController.attach(
      zoomBy: _zoomBy,
      animateTo: _animateTo,
      resetRotation: _resetRotation,
    );
  }

  void _prepareMarkerIconsIfNeeded({bool force = false}) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final String markerSignature = _buildMarkerSignature();
    if (!force && _preparedPixelRatio == pixelRatio && _preparedMarkerSignature == markerSignature) {
      return;
    }

    // A pixel ratio change invalidates every bitmap we drew for the old one.
    if (_preparedPixelRatio != pixelRatio) _iconByCacheKey.clear();

    _preparedPixelRatio = pixelRatio;
    _preparedMarkerSignature = markerSignature;
    _prepareVersion += 1;

    // Show whatever is already cached before awaiting anything, so markers
    // that have been drawn before appear on this frame rather than after the
    // first async gap.
    _emitMarkers();

    final SpGoogleMapMarkerIconBuilder<T>? markerIconBuilder = widget.markerIconBuilder;
    if (markerIconBuilder == null) return;

    unawaited(
      _prepareMarkerIcons(
        markerIconBuilder: markerIconBuilder,
        pixelRatio: pixelRatio,
        prepareVersion: _prepareVersion,
      ),
    );
  }

  /// Draws the icons this marker set needs that aren't cached yet.
  ///
  /// Deliberately sequential: the decode parallelises on engine workers, but
  /// `toImage()` lands on the raster thread, so running these concurrently
  /// mostly just competes with the drag the user is in the middle of.
  /// Throughput isn't the goal — [_emitMarkersBatchSize] is, since pins that
  /// trickle in read as faster than a set that appears all at once later.
  Future<void> _prepareMarkerIcons({
    required SpGoogleMapMarkerIconBuilder<T> markerIconBuilder,
    required double pixelRatio,
    required int prepareVersion,
  }) async {
    int builtSinceEmit = 0;
    _evictUnusedIcons();

    for (final SpMapMarker<T> marker in widget.markers) {
      final String cacheKey = marker.iconCacheKey ?? marker.id;
      if (_iconByCacheKey.containsKey(cacheKey)) continue;

      final BitmapDescriptor icon = await markerIconBuilder(context, marker, pixelRatio);
      if (!mounted) return;

      _iconByCacheKey[cacheKey] = icon;
      builtSinceEmit++;

      if (builtSinceEmit >= _emitMarkersBatchSize) {
        builtSinceEmit = 0;
        _emitMarkers();
      }

      // A newer run has taken over. Everything drawn so far is already in the
      // cache, so stopping here costs nothing — the old code discarded it and
      // redrew from scratch on every viewport change during a drag.
      if (prepareVersion != _prepareVersion) return;
    }

    if (builtSinceEmit > 0) _emitMarkers();
  }

  /// Trims the cache oldest-first, but never drops an icon the current marker
  /// set still needs — evicting one of those would leave a default pin on
  /// screen with nothing to trigger a redraw. The cap can be exceeded by at
  /// most the number of visible markers, which is bounded by the caller.
  void _evictUnusedIcons() {
    if (_iconByCacheKey.length <= _maxCachedIcons) return;

    final Set<String> inUse = <String>{
      for (final SpMapMarker<T> marker in widget.markers) marker.iconCacheKey ?? marker.id,
    };

    for (final String key in _iconByCacheKey.keys.toList()) {
      if (_iconByCacheKey.length <= _maxCachedIcons) break;
      if (inUse.contains(key)) continue;
      _iconByCacheKey.remove(key);
    }
  }

  void _emitMarkers() {
    if (!mounted) return;

    final Map<MarkerId, Marker> markers = _buildGoogleMarkers();
    _displayedIconByMarkerId.removeWhere((markerId, _) => !markers.containsKey(MarkerId(markerId)));
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  Map<MarkerId, Marker> _buildGoogleMarkers() {
    final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
    for (final SpMapMarker<T> marker in widget.markers) {
      final MarkerId markerId = MarkerId(marker.id);

      // Reusing the cached instance matters beyond skipping the redraw:
      // BitmapDescriptor has no `operator ==`, so Marker equality falls back
      // to identity here. A freshly built descriptor makes every marker look
      // changed, and the plugin re-sends all of them over the platform
      // channel to be decoded natively again.
      //
      // Falling back to whatever this pin already shows covers the gap while
      // its next appearance is still being drawn.
      final BitmapDescriptor? icon =
          _iconByCacheKey[marker.iconCacheKey ?? marker.id] ?? _displayedIconByMarkerId[marker.id];

      // Never drawn at all: leave it off the map rather than flashing Google's
      // default red pin where a photo is about to land. Pins appear as their
      // bitmaps finish instead of all at once at the end.
      if (icon == null && widget.markerIconBuilder != null) continue;
      if (icon != null) _displayedIconByMarkerId[marker.id] = icon;

      markers[markerId] = Marker(
        markerId: markerId,
        clusterManagerId: marker.clusterable ? _clusterManagerId : null,
        position: _toLatLng(marker.point),
        icon: icon ?? BitmapDescriptor.defaultMarker,
        anchor: marker.anchor,
        consumeTapEvents: widget.onMarkerTap != null,
        infoWindow: InfoWindow(
          title: marker.title,
          snippet: marker.snippet,
        ),
        onTap: () => widget.onMarkerTap?.call(marker),
      );
    }
    return markers;
  }

  String _buildMarkerSignature() {
    return widget.markers
        .map(
          (marker) => <Object?>[
            marker.id,
            marker.point.latitude,
            marker.point.longitude,
            marker.title,
            marker.snippet,
            marker.clusterable,
            marker.size.width,
            marker.size.height,
            marker.anchor.dx,
            marker.anchor.dy,
            // Without this, a pin whose photo finished loading keeps the
            // placeholder it was first drawn with: the marker set is
            // unchanged, so the early return above skips the redraw.
            marker.iconCacheKey,
          ].join(':'),
        )
        .join('|');
  }

  Future<void> _handleClusterTap(Cluster cluster) async {
    final ValueChanged<List<SpMapMarker<T>>>? onClusterTap = widget.onClusterTap;
    if (onClusterTap != null) {
      final List<SpMapMarker<T>> clusterMarkers = widget.markers
          .where((marker) => _latLngWithinBounds(cluster.bounds, marker.point))
          .toList();
      if (clusterMarkers.isNotEmpty) {
        onClusterTap(clusterMarkers);
        return;
      }
    }

    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(cluster.bounds, 84.0),
      );
      return;
    } catch (_) {
      final double nextZoom = (_currentZoom + 2.0).clamp(3.0, 19.0).toDouble();
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.position, nextZoom),
      );
    }
  }

  Future<void> _zoomBy(double delta) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    final double nextZoom = (_currentZoom + delta).clamp(3.0, 19.0).toDouble();
    await controller.animateCamera(CameraUpdate.zoomTo(nextZoom));
  }

  Future<void> _animateTo(
    double latitude,
    double longitude, {
    double? zoom,
    double? bearing,
  }) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    final LatLng position = LatLng(latitude, longitude);
    final CameraPosition nextPosition = CameraPosition(
      target: position,
      zoom: zoom ?? _currentZoom,
      bearing: bearing ?? _currentBearing,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(nextPosition),
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _resetRotation() async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentCenter,
          zoom: _currentZoom,
          bearing: 0.0,
        ),
      ),
    );
  }

  MapType _toGoogleMapType(SpMapStyle mapStyle) {
    switch (mapStyle) {
      case SpMapStyle.streets:
        return MapType.normal;
      case SpMapStyle.satellite:
        return MapType.hybrid;
    }
  }

  LatLng _toLatLng(SpLatLng point) {
    return LatLng(point.latitude, point.longitude);
  }

  bool _latLngWithinBounds(LatLngBounds bounds, SpLatLng point) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;
    final bool latitudeWithin = latitude >= bounds.southwest.latitude && latitude <= bounds.northeast.latitude;

    final double west = bounds.southwest.longitude;
    final double east = bounds.northeast.longitude;
    final bool crossesDateLine = west > east;

    final bool longitudeWithin = crossesDateLine
        ? longitude >= west || longitude <= east
        : longitude >= west && longitude <= east;

    return latitudeWithin && longitudeWithin;
  }
}
