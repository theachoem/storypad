import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

class FontWeightTile extends StatelessWidget {
  const FontWeightTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider provider = Provider.of<ThemeProvider>(context);

    return SpPopupMenuButton(
      smartDx: true,
      dyGetter: (dy) => dy + 44.0,
      items: (context) => FontWeight.values.map((fontWeight) {
        final descriptions = {
          100: 'Thin',
          200: 'Extra-light',
          300: 'Light',
          400: 'Normal (default)',
          500: 'Medium',
          600: 'Semi-bold',
          700: 'Bold',
          800: 'Extra-bold',
          900: 'Black',
        };

        return SpPopMenuItem(
          selected: fontWeight == provider.theme.fontWeight,
          title: "${fontWeight.value} - ${descriptions[fontWeight.value]}",
          onPressed: () => provider.setFontWeight(fontWeight),
        );
      }).toList(),
      builder: (open) {
        return ListTile(
          leading: const Icon(Icons.format_size_outlined),
          title: const Text("Font Weight"),
          subtitle: Text(provider.theme.fontWeight.value.toString()),
          onTap: () => open(),
        );
      },
    );
  }
}
