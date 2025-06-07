import 'package:flutter/material.dart';
import 'extensions/theme_data.dart';

enum AdaptiveStyle {
  adaptive,
  material,
  @Deprecated('Use `ios` instead. Will be removed in v2.')
  cupertino,
  iOS,
  macOS;

  @Deprecated('Will be removed in v2.')
  bool isCupertinoStyle(ThemeData theme) =>
      this == AdaptiveStyle.cupertino ||
      (this == AdaptiveStyle.adaptive && theme.isCupertinoStyle);

  bool isMaterial(ThemeData theme) =>
      this == AdaptiveStyle.material ||
      (this == AdaptiveStyle.adaptive &&
          theme.platform == TargetPlatform.android);

  AdaptiveStyle effectiveStyle(ThemeData data) {
    switch (this) {
      case AdaptiveStyle.material:
      // ignore: deprecated_member_use_from_same_package
      case AdaptiveStyle.cupertino:
      case AdaptiveStyle.iOS:
      case AdaptiveStyle.macOS:
        // ignore: avoid_returning_this
        return this;
      case AdaptiveStyle.adaptive:
        switch (data.platform) {
          case TargetPlatform.iOS:
            return AdaptiveStyle.iOS;
          case TargetPlatform.macOS:
            return AdaptiveStyle.macOS;
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            return AdaptiveStyle.material;
        }
    }
  }

  String get label {
    switch (this) {
      case AdaptiveStyle.adaptive:
        return 'Adaptive';
      // ignore: deprecated_member_use_from_same_package
      case AdaptiveStyle.cupertino:
        return 'Cupertino';
      case AdaptiveStyle.iOS:
        return 'iOS';
      case AdaptiveStyle.macOS:
        return 'macOS';
      case AdaptiveStyle.material:
        return 'Material';
    }
  }
}
