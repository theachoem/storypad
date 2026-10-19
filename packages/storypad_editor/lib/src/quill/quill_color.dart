import 'dart:ui' show Color;

/// Colors as StoryPad's Quill editor wrote them.
class QuillColor {
  const QuillColor._();

  /// [color] as lowercase, zero-padded `#aarrggbb` (alpha first).
  static String format(Color color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
