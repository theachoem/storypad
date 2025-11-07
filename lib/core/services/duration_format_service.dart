/// Service for formatting durations into human-readable strings.
///
/// Provides consistent duration formatting across the app.
/// Supports both milliseconds and Dart Duration objects.
class DurationFormatService {
  /// Format milliseconds to "MM:SS" format
  ///
  /// Example:
  /// ```dart
  /// DurationFormatService.formatMs(120500) // Returns "02:00"
  /// DurationFormatService.formatMs(65000)  // Returns "01:05"
  /// DurationFormatService.formatMs(5000)   // Returns "00:05"
  /// ```
  static String formatMs(int ms) {
    final seconds = (ms ~/ 1000) % 60;
    final minutes = (ms ~/ (1000 * 60)) % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// Format Dart Duration to "MM:SS" format
  ///
  /// Example:
  /// ```dart
  /// DurationFormatService.formatDuration(Duration(minutes: 2))
  /// // Returns "02:00"
  /// ```
  static String formatDuration(Duration duration) {
    final seconds = duration.inSeconds % 60;
    final minutes = duration.inMinutes % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
