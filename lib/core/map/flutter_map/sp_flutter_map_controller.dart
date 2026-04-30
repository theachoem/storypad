import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/map/sp_map_controller.dart';

/// [SpMapController] implementation backed by `flutter_map`'s [MapController].
///
/// Create via [SpFlutterMapAdapter.createController] and pass to
/// [SpFlutterMapAdapter.buildMap]. The underlying [MapController] is ready
/// as soon as the [FlutterMap] widget is built.
class SpFlutterMapController implements SpMapController {
  final MapController _inner = MapController();

  /// The raw [MapController] — only use inside the `flutter_map` adapter.
  MapController get rawController => _inner;

  @override
  Future<void> animateTo(
    SpLatLng position, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _inner.move(
      LatLng(position.latitude, position.longitude),
      zoom ?? _inner.camera.zoom,
    );
  }

  @override
  Future<void> moveTo(SpLatLng position, {double? zoom}) async {
    _inner.move(
      LatLng(position.latitude, position.longitude),
      zoom ?? _inner.camera.zoom,
    );
  }
}
