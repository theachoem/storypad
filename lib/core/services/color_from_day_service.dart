import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/device_preferences_provider.dart';

class ColorFromDayService {
  final BuildContext context;

  ColorFromDayService({
    required this.context,
  });

  // Resolves a single weekday directly to avoid building the full map on every lookup (hot path: tiles/badges/markers).
  Color? get(int weekday) {
    final String? name = _colorNameFor(weekday);
    if (name == null) return null;
    return _resolve(name, _isDarkMode);
  }

  Color? getForeground() {
    return _isDarkMode ? Colors.black : Colors.white;
  }

  Map<int, Color> colors() {
    final bool darkMode = _isDarkMode;
    final Map<int, String>? names = _names;

    return {
      for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekday: _resolve(names?[weekday] ?? kDefaultColorNamesByDay[weekday]!, darkMode),
    };
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  // User customizations from the in-memory preferences (no extra cache needed).
  Map<int, String>? get _names => context.read<DevicePreferencesProvider>().preferences.colorByDay;

  String? _colorNameFor(int weekday) {
    return _names?[weekday] ?? kDefaultColorNamesByDay[weekday];
  }

  Color _resolve(String name, bool darkMode) {
    if (name == kBlackWhiteColorName) return darkMode ? Colors.white : Colors.black;

    final MaterialColor swatch = kMaterialColorsByName[name] ?? Colors.grey;
    return (darkMode ? swatch[300] : swatch[700])!;
  }
}
