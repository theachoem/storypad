import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';

class ColorSeedTile extends StatelessWidget {
  const ColorSeedTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DevicePreferencesProvider provider = Provider.of<DevicePreferencesProvider>(context);
    return SpFloatingPopUpButton(
      estimatedFloatingWidth: spColorPickerMinWidth,
      bottomToTop: false,
      dyGetter: (dy) => dy + 56,
      floatingBuilder: (close) {
        return SpColorPicker(
          position: SpColorPickerPosition.top,
          currentColor: provider.preferences.colorSeed,
          level: SpColorPickerLevel.one,
          onPickedColor: (color) {
            provider.setColorSeed(color);
            close();
          },
        );
      },
      builder: (void Function() open) {
        return ListTile(
          title: Text(tr("list_tile.color_seed.title")),
          subtitle: Text(provider.preferences.colorSeedCustomized ? tr("general.custom") : tr("general.default")),
          leading: Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.0),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.preferences.colorSeedCustomized
                    ? provider.preferences.colorSeed
                    : Theme.of(context).colorScheme.primary,
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
