import 'package:volume_controller/volume_controller.dart';

/// Notifies its listeners whenever the user turns the system volume up --
/// hardware keys, OS slider, anything.
///
/// The only place in the app that talks to `volume_controller` -- swap the
/// package out here and nowhere else.
///
/// Register in `initState` and unregister in `dispose`:
///
/// ```dart
/// DeviceVolumeService.instance.addOnIncreaseListener(_handleVolumeIncreased);
/// ...
/// DeviceVolumeService.instance.removeOnIncreaseListener(_handleVolumeIncreased);
/// ```
///
/// A singleton because `VolumeController` is one too, and it allows exactly
/// one listener: a second `addListener` silently cancels the first, and
/// `removeListener` cancels whoever holds it -- so screens alive at the same
/// time (the media viewer's `PageView` keeps neighbouring pages alive) would
/// steal it from each other if they each attached directly. Here they share
/// it: it's attached with the first listener and released with the last, so
/// nothing runs while nobody is listening.
class DeviceVolumeService {
  DeviceVolumeService._();

  static final DeviceVolumeService instance = DeviceVolumeService._();

  final List<void Function()> _listeners = [];

  // Baseline for the next change, seeded by the initial emission below.
  double? _lastVolume;

  void addOnIncreaseListener(void Function() listener) {
    _listeners.add(listener);
    if (_listeners.length == 1) _attach();
  }

  void removeOnIncreaseListener(void Function() listener) {
    if (!_listeners.remove(listener)) return;
    if (_listeners.isEmpty) _detach();
  }

  void _attach() {
    // Never show the OS volume overlay on our behalf; we only read here, and
    // any change is the user's own key press, which draws it already.
    VolumeController.instance.showSystemUI = false;

    // A platform failure must not take down the screens listening -- losing
    // volume events just means losing the reaction. The subscription is owned
    // by the plugin singleton and cancelled by _detach, so nothing to keep.
    VolumeController.instance.addListener(_handleVolume).onError((_) {});
  }

  void _detach() {
    VolumeController.instance.removeListener();
    _lastVolume = null;
  }

  void _handleVolume(double volume) {
    final previousVolume = _lastVolume;
    _lastVolume = volume;

    // The first emission is the current level rather than a change -- it only
    // exists to seed the baseline, so registering never fires a listener.
    if (previousVolume == null || volume <= previousVolume) return;

    // Copied because a listener may unregister itself (or another) when called.
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}
