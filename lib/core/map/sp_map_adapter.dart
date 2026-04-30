import 'package:flutter/material.dart';
import 'package:storypad/core/map/sp_map_controller.dart';
import 'package:storypad/core/map/sp_map_marker.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/map/sp_latlng.dart';

/// Abstract interface for cross-platform map rendering and camera control.
///
/// Business logic should ONLY interact with the map through the [mapAdapter]
/// singleton — never import concrete implementations directly.
///
/// ## Architecture
/// ```
/// View / ViewModel
///     ↓ (calls mapAdapter.buildMap / mapAdapter.createController)
/// SpMapAdapter (abstract interface)
///     ↓ (singleton selects by platform)
/// SpGoogleMapsAdapter   ← iOS / Android
/// SpFlutterMapAdapter   ← macOS / Windows / Linux
/// ```
abstract class SpMapAdapter {
  /// Creates a platform-specific [SpMapController].
  ///
  /// Call this once (e.g. in a ViewModel constructor), then pass the result
  /// to [buildMap]. The controller becomes usable once the map widget mounts.
  SpMapController createController();

  /// Returns the recommended [Brightness] for overlay UI (AppBar, FAB, etc.)
  /// on top of this tile style.
  ///
  /// Each adapter knows its tile appearance:
  /// - A light-background map needs [Brightness.light] overlay controls.
  /// - A dark-background map (satellite) needs [Brightness.dark] overlay controls.
  ///
  /// Use [SpMapOverlayTheme] to apply this to the controls subtree.
  Brightness overlayBrightness(SpMapTileStyle style);

  /// Builds the full map widget.
  ///
  /// [markers]         — items to render on the map.
  /// [tileStyle]       — streets or satellite.
  /// [initialPosition] — camera starting centre; defaults to a world view if null.
  /// [initialZoom]     — camera starting zoom level.
  /// [controller]      — optional controller for programmatic camera moves.
  Widget buildMap({
    required BuildContext context,
    required List<SpMapMarker> markers,
    required SpMapTileStyle tileStyle,
    SpLatLng? initialPosition,
    double initialZoom,
    SpMapController? controller,
  });
}
