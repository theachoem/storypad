// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:storypad/core/map/google_maps/sp_google_maps_controller.dart';
import 'package:storypad/core/map/sp_map_adapter.dart';
import 'package:storypad/core/map/sp_map_controller.dart';
import 'package:storypad/core/map/sp_map_marker.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/map/sp_latlng.dart';

/// [SpMapAdapter] implementation using `google_maps_flutter`.
///
/// Used on iOS and Android.
class SpGoogleMapsAdapter implements SpMapAdapter {
  /// Google Maps streets style has a white/light background, so overlay
  /// controls look best with a light theme.
  /// Satellite is a dark image, so controls use a dark theme.
  @override
  Brightness overlayBrightness(SpMapTileStyle style) {
    switch (style) {
      case SpMapTileStyle.streets:
        return Brightness.light;
      case SpMapTileStyle.satellite:
        return Brightness.dark;
    }
  }

  @override
  SpMapController createController() => SpGoogleMapsController();

  @override
  Widget buildMap({
    required BuildContext context,
    required List<SpMapMarker> markers,
    required SpMapTileStyle tileStyle,
    SpLatLng? initialPosition,
    double initialZoom = 13.0,
    SpMapController? controller,
    void Function(SpLatLng)? onTap,
  }) {
    final center = initialPosition != null
        ? gm.LatLng(initialPosition.latitude, initialPosition.longitude)
        : const gm.LatLng(20.0, 0.0);

    return _GoogleMapWidget(
      initialCameraPosition: gm.CameraPosition(
        target: center,
        zoom: initialPosition != null ? initialZoom : 2.0,
      ),
      mapType: tileStyle == SpMapTileStyle.satellite ? gm.MapType.satellite : gm.MapType.normal,
      markers: markers,
      controller: controller as SpGoogleMapsController?,
      onTap: onTap,
    );
  }
}

/// Internal widget that renders a [gm.GoogleMap] with native [gm.Marker]s.
///
/// All marker types in the [SpMapMarker] hierarchy map to native
/// [gm.BitmapDescriptor]s, so no Stack overlay or coordinate projection
/// is needed — Google Maps renders them at the correct geo-position at all
/// zoom levels and during camera animations.
///
/// [SpAssetMapMarker] descriptors are loaded asynchronously via
/// [gm.BitmapDescriptor.fromAssetImage] before the widget first draws;
/// [SpPinMapMarker] descriptors are computed synchronously from HSV hue.
class _GoogleMapWidget extends StatefulWidget {
  const _GoogleMapWidget({
    required this.initialCameraPosition,
    required this.mapType,
    required this.markers,
    this.controller,
    this.onTap,
  });

  final gm.CameraPosition initialCameraPosition;
  final gm.MapType mapType;
  final List<SpMapMarker> markers;
  final SpGoogleMapsController? controller;
  final void Function(SpLatLng)? onTap;

  @override
  State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<_GoogleMapWidget> {
  gm.GoogleMapController? _nativeController;

  /// Native [gm.Marker] set, rebuilt whenever [widget.markers] changes.
  Set<gm.Marker> _gmMarkers = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(_GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) _loadMarkers();
  }

  @override
  void dispose() {
    _nativeController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    final config = ImageConfiguration(
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );

    final markers = <gm.Marker>{};
    for (int i = 0; i < widget.markers.length; i++) {
      final m = widget.markers[i];
      final icon = await _iconFor(m, config);
      markers.add(
        gm.Marker(
          markerId: gm.MarkerId('sp_marker_$i'),
          position: gm.LatLng(m.position.latitude, m.position.longitude),
          icon: icon,
          infoWindow: m.infoWindowTitle != null ? gm.InfoWindow(title: m.infoWindowTitle) : gm.InfoWindow.noText,
        ),
      );
    }

    if (mounted) setState(() => _gmMarkers = markers);
  }

  /// Converts an [SpMapMarker] to a [gm.BitmapDescriptor].
  ///
  /// [SpPinMapMarker] is synchronous (HSV hue conversion).
  /// [SpAssetMapMarker] loads from the asset bundle (async).
  Future<gm.BitmapDescriptor> _iconFor(
    SpMapMarker marker,
    ImageConfiguration config,
  ) async {
    return switch (marker) {
      SpPinMapMarker(color: final color) =>
        color == null
            ? gm.BitmapDescriptor.defaultMarker
            : gm.BitmapDescriptor.defaultMarkerWithHue(
                HSVColor.fromColor(color).hue,
              ),
      SpAssetMapMarker(assetPath: final path, width: final w, height: final h) => gm.BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
          devicePixelRatio: config.devicePixelRatio,
          size: (w != null && h != null) ? Size(w, h) : null,
        ),
        path,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      mapType: widget.mapType,
      markers: _gmMarkers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onTap: widget.onTap != null ? (gm.LatLng pos) => widget.onTap!(SpLatLng(pos.latitude, pos.longitude)) : null,
      onMapCreated: (native) {
        _nativeController = native;
        widget.controller?.onMapCreated(native);
      },
    );
  }
}
