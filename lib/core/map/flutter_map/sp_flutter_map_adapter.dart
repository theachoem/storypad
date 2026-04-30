import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:storypad/core/map/flutter_map/sp_flutter_map_controller.dart';
import 'package:storypad/core/map/sp_map_adapter.dart';
import 'package:storypad/core/map/sp_map_controller.dart';
import 'package:storypad/core/map/sp_map_marker.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/map/sp_latlng.dart';

/// [SpMapAdapter] implementation using `flutter_map` + MapTiler tiles.
///
/// Used on macOS, Windows, and Linux where `google_maps_flutter` is unavailable.
class SpFlutterMapAdapter implements SpMapAdapter {
  /// MapTiler tile URL templates — implementation detail of this adapter only.
  String _tileUrl(SpMapTileStyle tileStyle) {
    switch (tileStyle) {
      case SpMapTileStyle.streets:
        return 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=cWUdEifZoUYEaZRNo6nt';
      case SpMapTileStyle.satellite:
        return 'https://api.maptiler.com/maps/hybrid-v4/{z}/{x}/{y}.png?key=cWUdEifZoUYEaZRNo6nt';
    }
  }

  /// MapTiler streets tiles use a light-coloured base map, so overlay
  /// controls look best with a light theme.
  /// Satellite tiles are dark, so controls use a dark theme.
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
  SpMapController createController() => SpFlutterMapController();

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
        ? LatLng(initialPosition.latitude, initialPosition.longitude)
        : const LatLng(20.0, 0.0);

    final mapController = (controller as SpFlutterMapController?)?.rawController;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialPosition != null ? initialZoom : 2.0,
        onTap: onTap != null ? (tapPosition, point) => onTap(SpLatLng(point.latitude, point.longitude)) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl(tileStyle),
          userAgentPackageName: 'com.tc.writestory',
        ),
        MarkerLayer(
          markers: markers.map(_buildMarker).toList(),
        ),
      ],
    );
  }

  Marker _buildMarker(SpMapMarker marker) {
    return Marker(
      point: LatLng(marker.position.latitude, marker.position.longitude),
      child: switch (marker) {
        SpPinMapMarker(color: final color) => Icon(
          Icons.location_pin,
          color: color ?? Colors.red,
          size: 32,
        ),
        SpAssetMapMarker(assetPath: final path, width: final w, height: final h) => Image.asset(
          path,
          width: w,
          height: h,
        ),
      },
    );
  }
}
