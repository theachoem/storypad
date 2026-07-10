import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/sp_adaptive_pop_up_button.dart';
import 'package:storypad/widgets/sp_color_picker.dart';

class ColorSeedTile extends StatelessWidget {
  const ColorSeedTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DevicePreferencesProvider provider = Provider.of<DevicePreferencesProvider>(context);

    return SpAdaptivePopUpButton(
      floatingBuilder: (close, openAbove) {
        return SpColorPicker(
          isDarkMode: AppTheme.isDarkMode(context),
          position: openAbove ? SpColorPickerPosition.bottom : SpColorPickerPosition.top,
          currentColor: provider.preferences.colorSeed,
          level: SpColorPickerLevel.one,
          onPickedColor: (color) async {
            await close();
            provider.setColorSeed(color);
          },
        );
      },
      builder: (void Function() open) {
        return ListTile(
          title: Text(context.tr("list_tile.color_seed.title")),
          subtitle: Text(
            provider.preferences.colorSeedCustomized ? context.tr("general.custom") : context.tr("general.default"),
          ),
          leading: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          onTap: () {
            open();
          },
        );
      },
    );
  }
}
