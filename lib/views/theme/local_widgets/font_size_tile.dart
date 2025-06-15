import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_size_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class FontSizeTile extends StatelessWidget {
  const FontSizeTile({
    super.key,
    required this.currentFontSize,
    required this.onChanged,
  });

  final FontSizeOption? currentFontSize;
  final void Function(FontSizeOption? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.fontSize),
      title: Text(tr('general.font_size')),
      subtitle: Text(currentFontSize?.label ?? tr('general.system')),
      onTap: () {
        SpFontSizeSheet(
          fontSize: currentFontSize,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }
}
