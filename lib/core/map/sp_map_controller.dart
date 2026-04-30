import 'package:storypad/core/map/sp_latlng.dart';

/// Abstract interface for cross-platform map camera control.
///
/// Business logic should ONLY interact with the map camera through this
/// interface — never use platform-specific controller types directly.
///
/// Obtain an instance via [SpMapAdapter.createController], then pass it to
/// [SpMapAdapter.buildMap]. The controller becomes usable once the map widget
/// has been mounted.
///
/// ```dart
/// final controller = mapAdapter.createController();
///
/// // In ViewModel or gesture handler:
/// await controller.animateTo(SpLatLng(11.56, 104.91), zoom: 14);
/// ```
abstract class SpMapController {
  /// Animate the camera to [position].
  ///
  /// [zoom] — target zoom level; keeps current zoom if null.
  /// [duration] — animation length (ignored on platforms without native support).
  Future<void> animateTo(
    SpLatLng position, {
    double? zoom,
    Duration duration,
  });

  /// Move the camera instantly (no animation) to [position].
  ///
  /// [zoom] — target zoom level; keeps current zoom if null.
  Future<void> moveTo(SpLatLng position, {double? zoom});
}
