import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/device_preferences_provider.dart';

class ColorFromDayService {
  final BuildContext context;

  ColorFromDayService({
    required this.context,
  });

  Color? get(int weekday) {
    return colors()[weekday];
  }

  Color? getForeground() {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;
    return darkMode ? Colors.black : Colors.white;
  }

  Map<int, Color> colors() {
    bool darkMode = Theme.of(context).brightness == Brightness.dark;

    // Read user customizations from the in-memory preferences (no extra cache needed).
    final Map<int, String>? names = context.read<DevicePreferencesProvider>().preferences.colorByDay;

    return {
      for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekday: _resolve(names?[weekday] ?? kDefaultColorNamesByDay[weekday]!, darkMode),
    };
  }

  Color _resolve(String name, bool darkMode) {
    if (name == kBlackWhiteColorName) return darkMode ? Colors.white : Colors.black;

    final MaterialColor swatch = kMaterialColorsByName[name] ?? Colors.grey;
    return (darkMode ? swatch[300] : swatch[700])!;
  }
}
