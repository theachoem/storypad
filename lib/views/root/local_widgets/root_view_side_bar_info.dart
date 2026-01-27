import 'package:flutter/material.dart';

class RootViewSideBarInfo {
  final bool bigScreen;
  final ColorScheme? colorScheme;
  final bool temporaryHidden;

  RootViewSideBarInfo({
    required this.bigScreen,
    required this.colorScheme,
    required this.temporaryHidden,
  });

  RootViewSideBarInfo copyWith({
    bool? bigScreen,
    bool? temporaryHidden,
  }) {
    return RootViewSideBarInfo(
      bigScreen: bigScreen ?? this.bigScreen,
      temporaryHidden: temporaryHidden ?? this.temporaryHidden,
      colorScheme: colorScheme,
    );
  }

  RootViewSideBarInfo copyWithColorScheme(ColorScheme? colorScheme) {
    return RootViewSideBarInfo(
      bigScreen: bigScreen,
      colorScheme: colorScheme,
      temporaryHidden: temporaryHidden,
    );
  }
}
