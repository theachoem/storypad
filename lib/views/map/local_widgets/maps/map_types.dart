import 'package:flutter/widgets.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/objects/sp_latlng.dart';

typedef SpMapViewportChanged = void Function(SpMapViewport viewport);

enum SpMapRenderer {
  googleMaps,
  flutterMap,
}

enum SpMapStyle {
  streets,
  satellite,
}

extension SpMapStyleExtension on SpMapStyle {
  String get label {
    switch (this) {
      case SpMapStyle.streets:
        return 'Streets';
      case SpMapStyle.satellite:
        return 'Satellite';
    }
  }

  String get mapTilerUrlTemplate {
    switch (this) {
      case SpMapStyle.streets:
        return 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=cWUdEifZoUYEaZRNo6nt';
      case SpMapStyle.satellite:
        return 'https://api.maptiler.com/maps/hybrid-v4/{z}/{x}/{y}.png?key=cWUdEifZoUYEaZRNo6nt';
    }
  }
}

class SpMapCamera {
  const SpMapCamera({
    required this.target,
    required this.zoom,
  });

  final SpLatLng target;
  final double zoom;
}

class SpMapViewport {
  const SpMapViewport({
    required this.bounds,
    required this.center,
    required this.zoom,
  });

  final SpLatLngBounds bounds;
  final SpLatLng center;
  final double zoom;
}

class SpMapMarker<T> {
  const SpMapMarker({
    required this.id,
    required this.point,
    required this.data,
    this.title,
    this.snippet,
    this.clusterable = true,
    this.size = const Size.square(42.0),
    this.alignment = Alignment.center,
    this.anchor = const Offset(0.5, 0.5),
  });

  final String id;
  final SpLatLng point;
  final T data;
  final String? title;
  final String? snippet;
  final bool clusterable;
  final Size size;
  final Alignment alignment;
  final Offset anchor;
}
