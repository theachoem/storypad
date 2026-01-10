import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpThemeModeIcon extends StatefulWidget {
  const SpThemeModeIcon({
    super.key,
    required this.parentContext,
    this.iconSize = 24.0,
    this.color,
  });

  final BuildContext parentContext;
  final double iconSize;
  final Color? color;

  @override
  State<SpThemeModeIcon> createState() => _SpThemeModeIconState();
}

class _SpThemeModeIconState extends State<SpThemeModeIcon> with DebounchedCallback {
  late bool isDarkMode = Theme.brightnessOf(widget.parentContext) == Brightness.dark;

  void setDarkMode(bool value) {
    if (value != isDarkMode) {
      isDarkMode = value;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        debouncedCallback(() {
          if (context.mounted) setDarkMode(provider.isDarkModeBaseOnThemeMode(context));
        });

        return SpAnimatedIcons.fadeScale(
          duration: Durations.long1,
          firstChild: Icon(
            SpIcons.darkMode,
            key: const ValueKey(Brightness.dark),
            size: widget.iconSize,
            color: widget.color,
          ),
          secondChild: Icon(
            SpIcons.lightMode,
            key: const ValueKey(Brightness.light),
            size: widget.iconSize,
            color: widget.color,
          ),
          showFirst: isDarkMode,
        );
      },
    );
  }
}
