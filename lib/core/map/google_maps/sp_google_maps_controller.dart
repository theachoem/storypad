import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/map/sp_map_controller.dart';

/// [SpMapController] implementation backed by `google_maps_flutter`'s
/// [gm.GoogleMapController].
///
/// Create via [SpGoogleMapsAdapter.createController] and pass to
/// [SpGoogleMapsAdapter.buildMap]. The underlying native controller is wired
/// up asynchronously via the map's `onMapCreated` callback — calls before
/// that point are silently dropped.
class SpGoogleMapsController implements SpMapController {
  gm.GoogleMapController? _inner;

  /// Called internally by [SpGoogleMapsAdapter] once the native map is ready.
  void onMapCreated(gm.GoogleMapController controller) {
    _inner = controller;
  }

  @override
  Future<void> animateTo(
    SpLatLng position, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    await _inner?.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.latitude, position.longitude),
          zoom: zoom ?? 13.0,
        ),
      ),
    );
  }

  @override
  Future<void> moveTo(SpLatLng position, {double? zoom}) async {
    await _inner?.moveCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.latitude, position.longitude),
          zoom: zoom ?? 13.0,
        ),
      ),
    );
  }
}
