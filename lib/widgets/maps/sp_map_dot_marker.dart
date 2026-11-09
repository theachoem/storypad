import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:storypad/widgets/maps/map_types.dart';

/// A small dot marking a place — e.g. places from past stories in a place picker:
/// a hint of where the user has been, quiet enough not to compete with the picker's pin.
///
/// Use the widget as a flutter_map `markerBuilder`, and [googleIcon] as a Google Maps
/// `markerIconBuilder` (with [iconCacheKeyFor] on every marker, so a style's dots share one bitmap).
class SpMapDotMarker extends StatelessWidget {
  const SpMapDotMarker({super.key, required this.mapStyle});

  final SpMapStyle mapStyle;

  static const double size = 14.0;

  /// Per map style, not the theme's primary (which can be black or white): teal stays clear of the
  /// red picker pin and the blue current-location dot — deeper on light tiles, brighter on dark imagery.
  static Color colorFor(SpMapStyle style) {
    return switch (style.overlayBrightness) {
      .light => const Color(0xFF00897B),
      .dark => const Color(0xFF1DE9B6),
    };
  }

  static String iconCacheKeyFor(SpMapStyle style) => 'sp_map_dot_marker_${style.name}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: .circle,
        color: colorFor(mapStyle),
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2.0)],
      ),
    );
  }

  static Future<BitmapDescriptor> googleIcon(SpMapStyle style, double pixelRatio) async {
    final color = colorFor(style);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    const center = Offset(size / 2, size / 2);

    canvas
      ..drawCircle(center, size / 2, Paint()..color = Colors.white)
      ..drawCircle(center, size / 2 - 2.0, Paint()..color = color);

    final picture = recorder.endRecording();
    final image = await picture.toImage((size * pixelRatio).round(), (size * pixelRatio).round());
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
      width: size,
      height: size,
    );
  }
}
