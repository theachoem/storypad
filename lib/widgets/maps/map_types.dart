import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/objects/sp_latlng.dart';

typedef SpMapViewportChanged = void Function(SpMapViewport viewport);

enum SpMapRenderer {
  googleMap,
  flutterMap;

  /// `google_maps_flutter` ships no macOS/Linux implementation, so desktop can
  /// only ever render flutter_map.
  static bool get googleMapSupported => Platform.isAndroid || Platform.isIOS;

  /// Platform capability, not user taste — the fallback when the user hasn't
  /// picked a provider. Read `DevicePreferencesProvider.mapRenderer` instead
  /// of this directly.
  static SpMapRenderer get defaultRenderer => googleMapSupported ? googleMap : flutterMap;

  /// IANA timezones covering mainland China, where Google Maps tiles don't
  /// load at all.
  ///
  /// `Asia/Shanghai` and `Asia/Urumqi` are the two current zones; the rest are
  /// legacy aliases some platforms still report. Hong Kong, Macau and Taipei
  /// are deliberately absent — Google Maps works there.
  static const Set<String> _googleMapsUnavailableTimezones = {
    'Asia/Shanghai',
    'Asia/Urumqi',
    'Asia/Chongqing',
    'Asia/Chungking',
    'Asia/Harbin',
    'Asia/Kashgar',
    'PRC',
  };

  /// Whether [timezone] places the device somewhere Google Maps can't load.
  ///
  /// Keyed on timezone rather than app language because the question is where
  /// the device *is*, not what it reads: someone in Shanghai running the app in
  /// English has the same blank map, and is the person most likely to go
  /// looking for this setting.
  static bool googleMapsUnavailableIn(String? timezone) {
    return timezone != null && _googleMapsUnavailableTimezones.contains(timezone);
  }

  /// Whether to offer the provider choice at all. Desktop has only one working
  /// engine, and everywhere else Google Maps loads fine, so the setting would
  /// just be one more thing to read past. Pass `kLocalTimezone`.
  static bool selectable(String? timezone) {
    return googleMapSupported && googleMapsUnavailableIn(timezone);
  }

  String get label {
    switch (this) {
      case SpMapRenderer.googleMap:
        return tr('general.map_provider.google_maps');
      case SpMapRenderer.flutterMap:
        return tr('general.map_provider.map_tiler');
    }
  }

  String get description {
    switch (this) {
      case SpMapRenderer.googleMap:
        return tr('general.map_provider.google_maps_description');
      case SpMapRenderer.flutterMap:
        return tr('general.map_provider.map_tiler_description');
    }
  }
}

enum SpMapStyle {
  streets,
  satellite;

  Brightness get overlayBrightness {
    switch (this) {
      case SpMapStyle.streets:
        return .light;
      case SpMapStyle.satellite:
        return .dark;
    }
  }
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
        return 'https://static.storypad.me/maptiler/streets/{z}/{x}/{y}.png';
      case SpMapStyle.satellite:
        return 'https://static.storypad.me/maptiler/hybrid-v4/{z}/{x}/{y}.png';
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
    this.anchor = const Offset(0.5, 0.5),
    this.iconCacheKey,
  });

  final String id;
  final SpLatLng point;
  final T data;
  final String? title;
  final String? snippet;
  final bool clusterable;
  final Size size;
  final Offset anchor;

  /// Identifies the *rendered appearance* of this marker, not the marker
  /// itself — two markers with the same key are drawn identically and can
  /// share one cached bitmap. Null means the caller has no stable appearance
  /// key yet; renderers still cache the result, but fall back to keying by
  /// [id] (or a placeholder color) instead, so it won't be shared with other
  /// markers.
  ///
  /// Keying on appearance rather than [id] is what lets a hundred pins that
  /// all fall back to the same weekday-coloured placeholder collapse onto a
  /// single bitmap, and lets a pin keep its bitmap while panning.
  final String? iconCacheKey;
}
