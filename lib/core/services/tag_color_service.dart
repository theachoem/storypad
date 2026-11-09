import 'package:flutter/material.dart';

typedef TagColors = ({Color background, Color foreground, Color swatch});

/// A tag's colors for one brightness, derived from the single color the user picked
/// ([TagDbModel.colorSeedValue]), so they adapt to light and dark mode.
///
/// - [TagColors.background] / [TagColors.foreground]: the chip in story labels, a tonal container and
///   its text color, readable together in both modes.
/// - [TagColors.swatch]: the same color as a small mark on a plain surface (the edit page's swatches,
///   the dot after a tag's title): one tone from the chip's toward the middle, darker in light mode
///   and lighter in dark mode. A plain circle of the chip's exact color reads fainter (light) or
///   darker (dark) than the chip itself, which its text color lifts.
class TagColorService {
  const TagColorService._();

  /// The colors offered on the edit tag page, all shown at once. Fewer than the theme's Color Seed
  /// swatches: as chips, several of those come out nearly the same (red/deep orange/brown/pink,
  /// blue/light blue/blue grey, cyan/grey, …). Tags saved with any other color still resolve.
  static const List<MaterialColor> palette = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.deepPurple,
    Colors.purple,
  ];

  static final Map<(int, Brightness), TagColors> _cache = {};

  static TagColors resolve(Color seed, Brightness brightness) {
    return _cache[(seed.toARGB32(), brightness)] ??= _derive(seed, brightness);
  }

  static TagColors _derive(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return (
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      // Same tonal palette: the chip is tone 90 (light) / 30 (dark), these are tone 80 / 40.
      swatch: brightness == .light ? scheme.primaryFixedDim : ColorScheme.fromSeed(seedColor: seed).primary,
    );
  }
}
