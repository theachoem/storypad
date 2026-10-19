import 'dart:ui' show Color;

/// Colors as the inline HTML in Markdown writes them: CSS hex, alpha last.
class CssColor {
  const CssColor._();

  /// [color] as lowercase, zero-padded `rrggbbaa` (CSS order, alpha last).
  static String hex(Color color) {
    String byte(double channel) => (channel * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '${byte(color.r)}${byte(color.g)}${byte(color.b)}${byte(color.a)}';
  }

  /// Reads a `#rrggbbaa` (or `#rrggbb`) color for [property] from a CSS `style` attribute.
  static Color? fromStyle(String? style, RegExp property) {
    if (style == null) return null;

    // Exactly 6 or 8 hex digits, not {6,8}: a 7-digit match would be invalid.
    final match = RegExp('${property.pattern}\\s*:\\s*#([0-9a-fA-F]{8}|[0-9a-fA-F]{6})\\b').firstMatch(style);
    final hex = match?.group(1);
    if (hex == null) return null;

    int channel(int start) => int.parse(hex.substring(start, start + 2), radix: 16);
    return Color.fromARGB(hex.length == 8 ? channel(6) : 255, channel(0), channel(2), channel(4));
  }
}
