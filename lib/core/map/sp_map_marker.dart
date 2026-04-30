import 'package:flutter/widgets.dart';
import 'package:storypad/core/map/sp_latlng.dart';

/// Sealed base class for all map markers.
///
/// Types are designed around what map SDKs can render natively, so no
/// workarounds (e.g. Stack overlays) are needed on any platform.
///
/// ## Types
/// - [SpPinMapMarker]   — default pin, optional color/hue.
/// - [SpAssetMapMarker] — image loaded from an asset file.
///
/// Each [SpMapAdapter] implementation pattern-matches on these types and
/// delegates to the SDK's native marker API.
sealed class SpMapMarker {
  const SpMapMarker({required this.position, this.infoWindowTitle});

  final SpLatLng position;

  /// Optional label shown in a tap info-window (Google Maps) or tooltip
  /// (flutter_map). Pass `null` to suppress the window entirely.
  final String? infoWindowTitle;
}

/// A standard pin marker with an optional color.
///
/// - On Google Maps: rendered as a native `BitmapDescriptor` pin,
///   with hue derived from [color] via HSV conversion.
/// - On flutter_map: rendered as an `Icon(Icons.location_pin)`.
class SpPinMapMarker extends SpMapMarker {
  const SpPinMapMarker({
    required super.position,
    super.infoWindowTitle,
    this.color,
  });

  /// Pin tint color. `null` uses the SDK default (red on Google Maps).
  final Color? color;
}

/// A marker whose icon is an asset image (e.g. `assets/images/pin.png`).
///
/// - On Google Maps: rendered via `BitmapDescriptor.fromAssetImage`.
///   The descriptor is loaded asynchronously before the map is drawn.
/// - On flutter_map: rendered as `Image.asset(assetPath)`.
class SpAssetMapMarker extends SpMapMarker {
  const SpAssetMapMarker({
    required super.position,
    super.infoWindowTitle,
    required this.assetPath,
    this.width,
    this.height,
  });

  final String assetPath;

  /// Logical pixel size hint used by Google Maps when loading the image.
  /// Has no effect on flutter_map (use CSS/layout constraints there).
  final double? width;
  final double? height;
}
