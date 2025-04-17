// TODO: fix color.value deprecation
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/theme/local_widgets/font_family_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpStoryThemeBottomSheet extends BaseBottomSheet {
  final StoryDbModel story;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  SpStoryThemeBottomSheet({
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildColorsList(
                context: context,
                notifier: notifier,
                theme: theme,
              ),
              // This give more problem on navigation.
              // Let's disable it for now.
              //
              // ThemeModeTile(
              //   currentThemeMode: theme.themeMode ?? ThemeMode.system,
              //   onChanged: (ThemeMode themeMode) {
              //     notifier.value = notifier.value.copyWith(themeMode: themeMode);
              //     onThemeChanged(notifier.value);
              //   },
              // ),
              FontWeightTile(
                currentFontWeight: theme.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
                onChanged: (value) {
                  notifier.value = notifier.value.copyWith(fontWeightIndex: value.index);
                  onThemeChanged(notifier.value);
                },
              ),
              FontFamilyTile(
                showSheet: true,
                currentFontWeight: theme.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
                currentFontFamily: theme.fontFamily ?? kDefaultFontFamily,
                onChanged: (fontFamily) {
                  notifier.value = notifier.value.copyWith(fontFamily: fontFamily);
                  onThemeChanged(notifier.value);
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget buildColorsList({
    required BuildContext context,
    required CmValueNotifier<StoryPreferencesDbModel> notifier,
    required StoryPreferencesDbModel theme,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16.0),
      child: Row(spacing: 4.0, children: [
        buildButton(
          tooltip: tr("button.reset"),
          context: context,
          backgroundColor: null,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.value = notifier.value.copyWith(colorSeedValue: null);
            onThemeChanged(notifier.value);
          },
          selected: notifier.value.colorSeedValue == null,
          child: const Icon(SpIcons.hideSource),
        ),
        ...kMaterialColors.map<Widget>(
          (color) {
            return buildButton(
              context: context,
              child: null,
              backgroundColor: color,
              foregroundColor: Colors.black,
              selected: color.value == notifier.value.colorSeedValue,
              onTap: () {
                notifier.value = notifier.value.copyWith(colorSeedValue: color.value);
                onThemeChanged(notifier.value);
              },
            );
          },
        )
      ]),
    );
  }

  Widget buildButton({
    required VoidCallback onTap,
    required BuildContext context,
    required Widget? child,
    required Color? backgroundColor,
    required Color? foregroundColor,
    bool selected = false,
    String? tooltip,
  }) {
    Widget button = SpTapEffect(
      effects: [
        SpTapEffectType.border,
        SpTapEffectType.scaleDown,
      ],
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 2.0,
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: selected
              ? SpFadeIn.fromBottom(
                  child: Icon(
                  SpIcons.check,
                  color: foregroundColor,
                ))
              : child,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    } else {
      return button;
    }
  }
}
