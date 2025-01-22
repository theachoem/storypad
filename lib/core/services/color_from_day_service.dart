import 'package:flutter/material.dart';
import 'package:storypad/core/constants/utils_colors.dart';

class ColorFromDayService {
  final BuildContext context;

  ColorFromDayService({
    required this.context,
  });

  Color? get(int day) {
    return colors()[day];
  }

  Map<int, Color> colors() {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;
    return darkMode ? colorsByDayDark : colorsByDayLight;
  }
}
