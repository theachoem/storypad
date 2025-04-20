import 'dart:async';

class RelaxSoundsTimerService {
  final void Function() onEnded;

  bool get ended => _stopIn == null || _stopIn?.inSeconds == 0;

  RelaxSoundsTimerService({
    required this.onEnded,
  });

  Timer? _stopTimer;
  Duration? _stopIn;
  Duration? get stopIn => _stopIn;

  void setStopIn(Duration? duration) {
    if (duration == null || duration <= Duration.zero) {
      _stopIn = null;
      return;
    }

    _stopIn = duration;
  }

  void pauseIfNot() {
    _stopTimer?.cancel();
    _stopTimer = null;
  }

  void startIfNot() {
    if (ended) _stopIn = const Duration(minutes: 30);

    _stopTimer?.cancel();
    _stopTimer = null;
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopIn != null) _stopIn = _stopIn! - const Duration(seconds: 1);

      if (_stopIn == null || _stopIn?.inSeconds == 0) {
        _stopIn = null;
        _stopTimer?.cancel();
        _stopTimer = null;

        onEnded();
      }
    });
  }
}
