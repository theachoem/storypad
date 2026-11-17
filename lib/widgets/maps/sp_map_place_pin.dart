import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:storypad/widgets/maps/sp_map_center_pin.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// A place pinned to its spot on the map — the story's place in the Map tab's view mode. Drawn like
/// [SpMapCenterPin] at rest, so the two can take each other's place without a jump.
///
/// Its box is centered on the spot (the pin above it, empty space below), so it needs no anchor: use the
/// widget as a flutter_map `markerBuilder` and [googleIcon] as a Google Maps `markerIconBuilder`, on a
/// marker of [size] with [iconCacheKey].
class SpMapPlacePin extends StatelessWidget {
  const SpMapPlacePin({super.key});

  static const double _pinSize = 48.0;
  static const double _dotSize = 6.0;

  static const double _height = 112.0;

  // The pin's bottom sits 3px above the spot, and the dot is centered on it: as [SpMapCenterPin] at rest.
  static const double _pinTop = _height / 2 - 3.0 - _pinSize;

  static const Size size = Size(_pinSize, _height);
  static const String iconCacheKey = 'sp_map_place_pin';

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: Column(
        children: [
          const SizedBox(height: _pinTop),
          const Icon(SpIcons.locationPin, size: _pinSize, color: SpMapCenterPin.color),
          DecoratedBox(
            decoration: BoxDecoration(color: SpMapCenterPin.color.withValues(alpha: 0.8), shape: .circle),
            child: const SizedBox.square(dimension: _dotSize),
          ),
        ],
      ),
    );
  }

  static Future<BitmapDescriptor> googleIcon(double pixelRatio) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);

    const icon = SpIcons.locationPin;
    final painter = TextPainter(
      textDirection: .ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: _pinSize,
          height: 1.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: SpMapCenterPin.color,
        ),
      ),
    )..layout();
    painter.paint(canvas, Offset((size.width - painter.width) / 2, _pinTop));
    painter.dispose();

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      _dotSize / 2,
      Paint()..color = SpMapCenterPin.color.withValues(alpha: 0.8),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage((size.width * pixelRatio).round(), (size.height * pixelRatio).round());
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
      width: size.width,
      height: size.height,
    );
  }
}
