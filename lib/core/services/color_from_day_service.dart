import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';

class ColorFromDayService {
  final BuildContext context;

  ColorFromDayService({
    required this.context,
  });

  Color? get(int weekday) {
    return colors()[weekday];
  }

  Map<int, Color> colors() {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;
    return darkMode ? kColorsByDayDark : kColorsByDayLight;
  }
}
