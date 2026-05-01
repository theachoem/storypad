typedef SpMapZoomBy = Future<void> Function(double delta);

typedef SpMapAnimateTo =
    Future<void> Function(
      double latitude,
      double longitude, {
      double? zoom,
      double? bearing,
    });

typedef SpMapResetRotation = Future<void> Function();

class SpMapController {
  SpMapZoomBy? _zoomBy;
  SpMapAnimateTo? _animateTo;
  SpMapResetRotation? _resetRotation;

  void attach({
    required SpMapZoomBy zoomBy,
    required SpMapAnimateTo animateTo,
    required SpMapResetRotation resetRotation,
  }) {
    _zoomBy = zoomBy;
    _animateTo = animateTo;
    _resetRotation = resetRotation;
  }

  void detach() {
    _zoomBy = null;
    _animateTo = null;
    _resetRotation = null;
  }

  Future<void> zoomBy(double delta) async {
    await _zoomBy?.call(delta);
  }

  Future<void> animateTo(
    double latitude,
    double longitude, {
    double? zoom,
    double? bearing,
  }) async {
    await _animateTo?.call(latitude, longitude, zoom: zoom, bearing: bearing);
  }

  Future<void> resetRotation() async {
    await _resetRotation?.call();
  }
}
