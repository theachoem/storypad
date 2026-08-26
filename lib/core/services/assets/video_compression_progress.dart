import 'package:flutter/foundation.dart';
import 'package:video_compressor_plus/video_compressor_plus.dart';

/// Shared state between the pick-time compression loop (`AppFilePickerService`)
/// and the screen covering it (`VideoCompressionView`): which video of the
/// batch is being re-encoded, how far along it is, and whether the user asked
/// to stop.
///
/// It owns the `video_compress` progress subscription rather than leaving that
/// to the widget, so the screen stays a dumb renderer -- and because that
/// stream is single-subscription: exactly one of these may be alive at a time,
/// which the one-compression-at-a-time flow already guarantees.
class VideoCompressionProgress extends ChangeNotifier {
  VideoCompressionProgress({required this.total}) {
    _subscription = VideoCompress.compressProgress$.subscribe((percent) {
      _fraction = (percent / 100).clamp(0.0, 1.0);
      notifyListeners();
    });
  }

  /// How many videos this batch will re-encode (1 for a single pick).
  final int total;

  Subscription? _subscription;

  int _current = 0;

  /// 1-based position of the video being re-encoded, for "Video 2 of 3".
  int get current => _current;

  double _fraction = 0.0;

  /// Progress through the *current* video, 0..1. Stays 0 until the encoder
  /// reports its first tick, which the screen shows as indeterminate.
  double get fraction => _fraction;

  /// Progress through the whole batch, 0..1 -- what the bar actually shows, so
  /// a three-video pick doesn't restart the bar three times.
  double get overallFraction {
    if (total <= 0) return 0.0;
    return (((_current - 1).clamp(0, total) + _fraction) / total).clamp(0.0, 1.0);
  }

  bool _cancelled = false;

  /// Set once the user taps cancel. The loop checks it before each video, so
  /// cancelling stops the rest of the batch too, not just the running encode.
  bool get cancelled => _cancelled;

  /// Called by the loop as it reaches each video ([index] is 0-based).
  void startVideo(int index) {
    _current = index + 1;
    _fraction = 0.0;
    notifyListeners();
  }

  /// Stops the running encode and the rest of the batch. Everything not yet
  /// compressed is kept at its original quality -- the same fallback every
  /// other failure path in `VideoCompressionService` takes.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
    VideoCompress.cancelCompression();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _subscription = null;
    super.dispose();
  }
}
