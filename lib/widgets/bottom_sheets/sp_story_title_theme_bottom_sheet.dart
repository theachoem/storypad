// TODO: fix color.value deprecation
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/theme/local_widgets/font_family_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpStoryTitleThemeBottomSheet extends BaseBottomSheet {
  final StoryDbModel story;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  SpStoryTitleThemeBottomSheet({
    required this.story,
    required this.onThemeChanged,
  });

  @override
  bool get fullScreen => false;

  @override
  Color? get barrierColor => Colors.black12;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: story.preferences,
      builder: (context, theme, notifier) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FontWeightTile(
                currentFontWeight:
                    theme.titleFontWeight ?? theme.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
                onChanged: (value) {
                  notifier.value = notifier.value.copyWith(titleFontWeightIndex: value.index);
                  onThemeChanged(notifier.value);
                },
              ),
              FontFamilyTile(
                showSheet: true,
                currentFontWeight:
                    theme.titleFontWeight ?? theme.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
                currentFontFamily:
                    theme.titleFontFamily ?? theme.fontFamily ?? context.read<ThemeProvider>().theme.fontFamily,
                onChanged: (fontFamily) {
                  notifier.value = notifier.value.copyWith(titleFontFamily: fontFamily);
                  onThemeChanged(notifier.value);
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 12.0),
              OutlinedButton.icon(
                label: Text(tr('button.reset')),
                icon: const Icon(SpIcons.refresh),
                onPressed: notifier.value.titleReseted
                    ? null
                    : () {
                        notifier.value = notifier.value.copyWith(
                          titleFontFamily: null,
                          titleFontWeightIndex: null,
                        );
                        onThemeChanged(notifier.value);
                      },
              ),
              const SizedBox(height: 8.0),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
