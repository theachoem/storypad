import 'package:flutter/material.dart';

typedef TagColors = ({Color background, Color foreground, Color dot});

/// A tag's colors for one brightness, derived from the single color the user picked
/// ([TagDbModel.colorSeedValue]), so they adapt to light and dark mode.
///
/// - [TagColors.background] / [TagColors.foreground]: the chip in story labels (a tonal container
///   and its text color, readable together in both modes).
/// - [TagColors.dot]: the stronger tone, for a small dot on a plain surface (e.g. after a tag's title).
class TagColorService {
  const TagColorService._();

  static final Map<(int, Brightness), TagColors> _cache = {};

  static TagColors resolve(Color seed, Brightness brightness) {
    return _cache[(seed.toARGB32(), brightness)] ??= _derive(seed, brightness);
  }

  static TagColors _derive(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return (background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer, dot: scheme.primary);
  }
}
