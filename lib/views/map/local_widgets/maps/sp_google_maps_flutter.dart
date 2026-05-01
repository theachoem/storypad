import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/views/map/local_widgets/maps/map_types.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_map_controller.dart';

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
    this.markerIconBuilder,
    this.onViewportChanged,
    this.showCurrentLocation = true,
  });

  final SpMapController mapController;
  final SpMapCamera initialCamera;
  final EdgeInsets padding;
  final SpMapStyle mapStyle;
  final List<SpMapMarker<T>> markers;
  final ValueChanged<SpLatLng>? onMapTap;
  final ValueChanged<SpMapMarker<T>>? onMarkerTap;
  final SpGoogleMapMarkerIconBuilder<T>? markerIconBuilder;
  final SpMapViewportChanged? onViewportChanged;
  final bool showCurrentLocation;

  @override
  State<SpGoogleMap<T>> createState() => _SpGoogleMapState<T>();
}

class _SpGoogleMapState<T> extends State<SpGoogleMap<T>> with DebounchedCallback {
  // Cluster only show when there are at least 4 markers.
  static const ClusterManagerId _clusterManagerId = ClusterManagerId('sp_map_markers');
  late final Map<ClusterManagerId, ClusterManager> _clusterManagers;

  GoogleMapController? _googleMapController;
  late LatLng _currentCenter;
  double _currentZoom = 10.8;
  double _currentBearing = 0.0;
  double? _preparedPixelRatio;
  String? _preparedMarkerSignature;
  int _prepareVersion = 0;
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};

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

    _preparedPixelRatio = pixelRatio;
    _preparedMarkerSignature = markerSignature;
    _prepareVersion += 1;

    final SpGoogleMapMarkerIconBuilder<T>? markerIconBuilder = widget.markerIconBuilder;
    if (markerIconBuilder == null) {
      final Map<MarkerId, Marker> markers = _buildGoogleMarkers(
        iconForMarker: (_) => BitmapDescriptor.defaultMarker,
      );
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
      return;
    }

    unawaited(
      _prepareMarkerIcons(
        markerIconBuilder: markerIconBuilder,
        pixelRatio: pixelRatio,
        prepareVersion: _prepareVersion,
      ),
    );
  }

  Future<void> _prepareMarkerIcons({
    required SpGoogleMapMarkerIconBuilder<T> markerIconBuilder,
    required double pixelRatio,
    required int prepareVersion,
  }) async {
    final Map<MarkerId, BitmapDescriptor> icons = <MarkerId, BitmapDescriptor>{};
    for (final SpMapMarker<T> marker in widget.markers) {
      final MarkerId markerId = MarkerId(marker.id);
      icons[markerId] = await markerIconBuilder(context, marker, pixelRatio);
      if (!mounted || prepareVersion != _prepareVersion) return;
    }

    if (!mounted || prepareVersion != _prepareVersion) return;

    final Map<MarkerId, Marker> markers = _buildGoogleMarkers(
      iconForMarker: (marker) => icons[MarkerId(marker.id)] ?? BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  Map<MarkerId, Marker> _buildGoogleMarkers({
    required BitmapDescriptor Function(SpMapMarker<T> marker) iconForMarker,
  }) {
    final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
    for (final SpMapMarker<T> marker in widget.markers) {
      final MarkerId markerId = MarkerId(marker.id);
      markers[markerId] = Marker(
        markerId: markerId,
        clusterManagerId: marker.clusterable ? _clusterManagerId : null,
        position: _toLatLng(marker.point),
        icon: iconForMarker(marker),
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
          ].join(':'),
        )
        .join('|');
  }

  Future<void> _handleClusterTap(Cluster cluster) async {
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
    await controller.animateCamera(CameraUpdate.newCameraPosition(nextPosition));
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
}
