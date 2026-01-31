import 'package:flutter/material.dart';

class RootViewSideBarInfo {
  final ColorScheme? colorScheme;
  final bool temporaryHidden;

  RootViewSideBarInfo({
    required this.colorScheme,
    required this.temporaryHidden,
  });

  RootViewSideBarInfo copyWith({
    bool? bigScreen,
    bool? temporaryHidden,
  }) {
    return RootViewSideBarInfo(
      temporaryHidden: temporaryHidden ?? this.temporaryHidden,
      colorScheme: colorScheme,
    );
  }

  RootViewSideBarInfo copyWithColorScheme(ColorScheme? colorScheme) {
    return RootViewSideBarInfo(
      colorScheme: colorScheme,
      temporaryHidden: temporaryHidden,
    );
  }
}
