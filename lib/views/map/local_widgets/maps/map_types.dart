import 'package:flutter/widgets.dart';

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

class SpMapPoint {
  const SpMapPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class SpMapCamera {
  const SpMapCamera({
    required this.target,
    required this.zoom,
  });

  final SpMapPoint target;
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
  final SpMapPoint point;
  final T data;
  final String? title;
  final String? snippet;
  final bool clusterable;
  final Size size;
  final Alignment alignment;
  final Offset anchor;
}
