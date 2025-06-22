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
  });

  final BuildContext parentContext;

  @override
  State<SpThemeModeIcon> createState() => _SpThemeModeIconState();
}

class _SpThemeModeIconState extends State<SpThemeModeIcon> with DebounchedCallback {
  late bool isDarkMode = Theme.brightnessOf(widget.parentContext) == Brightness.dark;

  void setDarkMode(bool value) {
    if (value != isDarkMode) {
      isDarkMode = value;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        debouncedCallback(() {
          setDarkMode(provider.isDarkModeBaseOnThemeMode(context));
        });

        return SpAnimatedIcons.fadeScale(
          duration: Durations.long1,
          firstChild: const Icon(SpIcons.darkMode, key: ValueKey(Brightness.dark)),
          secondChild: const Icon(SpIcons.lightMode, key: ValueKey(Brightness.light)),
          showFirst: isDarkMode,
        );
      },
    );
  }
}
