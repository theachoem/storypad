// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

extension ColorSchemeExtension on ColorScheme {
  _M3ReadOnlyColor get readOnly => _M3ReadOnlyColor(this);
  M3CustomColor get bootstrap => M3CustomColor.getScheme(brightness);
}

/// Used in extension [ColorSchemeExtension]
class _M3ReadOnlyColor {
  final ColorScheme _color;
  _M3ReadOnlyColor(this._color);

  Color? get surface1 {
    return Color.alphaBlend(
      _color.primary.withValues(alpha: 0.05),
      _color.surface,
    );
  }

  Color? get surface2 {
    return Color.alphaBlend(
      _color.primary.withValues(alpha: 0.08),
      _color.surface,
    );
  }

  Color? get surface3 {
    return Color.alphaBlend(
      _color.primary.withValues(alpha: 0.11),
      _color.surface,
    );
  }

  Color? get surface4 {
    return Color.alphaBlend(
      _color.primary.withValues(alpha: 0.12),
      _color.surface,
    );
  }

  Color? get surface5 {
    return Color.alphaBlend(
      _color.primary.withValues(alpha: 0.14),
      _color.surface,
    );
  }

  Color? get black => const Color(0xFF000000);
  Color? get white => const Color(0xFFFFFFFF);
}

class _Scheme {
  final Color color;
  final Color onColor;
  final Color container;
  final Color onContainer;

  _Scheme(
    this.color,
    this.onColor,
    this.container,
    this.onContainer,
  );
}

/// Base on bootstrap:
/// https://getbootstrap.com/docs/4.0/utilities/colors
class M3CustomColor {
  final _Scheme success;
  final _Scheme danger;
  final _Scheme warning;
  final _Scheme info;

  M3CustomColor._({
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
  });

  static final Map<Brightness, M3CustomColor> _cached = {};
  static M3CustomColor getScheme(Brightness brightness) {
    Color success = const Color(0xFF28a745);
    Color danger = const Color(0xFFdc3545);
    Color warning = const Color(0xFFffc107);
    Color info = const Color(0xFF17a2b8);

    return _cached[brightness] ??= M3CustomColor._(
      success: _schemeFrom(success, brightness),
      danger: _schemeFrom(danger, brightness),
      warning: _schemeFrom(warning, brightness),
      info: _schemeFrom(info, brightness),
    );
  }

  static _Scheme _schemeFrom(Color color, Brightness brightness) {
    ColorScheme scheme = ColorScheme.fromSeed(seedColor: color, brightness: brightness);
    return _Scheme(
      scheme.primary,
      scheme.onPrimary,
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    );
  }
}
