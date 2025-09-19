import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_size_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class FontSizeTile extends StatelessWidget {
  const FontSizeTile({
    super.key,
    required this.currentFontSize,
    required this.onChanged,
    this.isDefaultToSystem = false,
  });

  final FontSizeOption? currentFontSize;
  final bool isDefaultToSystem;
  final void Function(FontSizeOption? value) onChanged;

  static Widget globalTheme() {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return FontSizeTile(
          currentFontSize: provider.preferences.fontSize,
          isDefaultToSystem: true,
          onChanged: (fontSize) => provider.setFontSize(fontSize),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? label = currentFontSize?.label;

    if (isDefaultToSystem) {
      label ??= tr('general.system');
    } else {
      label ??= tr('general.default');
    }

    return ListTile(
      leading: const Icon(SpIcons.fontSize),
      title: Text(tr('general.font_size')),
      subtitle: Text(label),
      onTap: () {
        SpFontSizeSheet(
          fontSize: currentFontSize,
          onChanged: onChanged,
          isDefaultToSystem: isDefaultToSystem,
        ).show(context: context);
      },
    );
  }
}
