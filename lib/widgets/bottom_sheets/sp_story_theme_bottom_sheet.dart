// TODO: fix color.value deprecation
// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/views/theme/local_widgets/font_family_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_info_sheet.dart';
import 'package:storypad/widgets/sp_color_list_selector.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpStoryThemeBottomSheet extends BaseBottomSheet {
  final StoryDbModel story;
  final StoryContentDbModel? draftContent;
  final BaseStoryViewModel viewModel;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  SpStoryThemeBottomSheet({
    required this.story,
    required this.draftContent,
    required this.viewModel,
    required this.onThemeChanged,
  });

  @override
  bool get fullScreen => false;

  @override
  Color? get barrierColor => Colors.black26;

  @override
  bool get showMaterialDragHandle => false;

  @override
  double get cupertinoPaddingTop => 0.0;

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
              const SizedBox(height: 4.0),
              buildHeader(notifier),
              const SizedBox(height: 8.0),
              SpColorListSelector(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                selectedColor: notifier.value.colorSeed,
                onChanged: (color) {
                  notifier.value = notifier.value.copyWith(colorSeedValue: color?.value);
                  onThemeChanged(notifier.value);
                },
              ),
              const SizedBox(height: 8.0),
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
                currentFontWeight: theme.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
                currentFontFamily: theme.fontFamily ?? context.read<ThemeProvider>().theme.fontFamily,
                onChanged: (fontFamily) {
                  notifier.value = notifier.value.copyWith(fontFamily: fontFamily);
                  onThemeChanged(notifier.value);
                },
              ),
              ListTile(
                leading: Icon(SpIcons.book),
                title: Text(tr("button.manage_pages")),
                subtitle: Text(plural('plural.page', draftContent?.richPages?.length ?? 0)),
                trailing: const Icon(SpIcons.keyboardRight),
                onTap: () async {
                  await Navigator.maybePop(context);
                  FocusManager.instance.primaryFocus?.unfocus();
                  viewModel.pagesManager.toggleManagingPage();
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 12.0),
              SpLayoutTypeSection(
                selected: notifier.value.layoutType,
                onThemeChanged: (layoutType) {
                  notifier.value = notifier.value.copyWith(layoutType: layoutType);
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

  Widget buildHeader(CmValueNotifier<StoryPreferencesDbModel> notifier) {
    return Row(
      mainAxisAlignment: kIsCupertino ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      children: [
        SpPopupMenuButton(
          dyGetter: (dy) => dy + 56,
          items: (context) {
            return [
              SpPopMenuItem(
                leadingIconData: SpIcons.info,
                title: tr("button.info"),
                onPressed: () => SpStoryInfoSheet(
                  story: viewModel.story!,
                  persisted: viewModel.flowType == EditingFlowType.update,
                ).show(context: context),
              ),
              SpPopMenuItem(
                leadingIconData: SpIcons.refresh,
                title: tr("button.reset_theme"),
                titleStyle: TextTheme.of(context)
                    .bodyMedium
                    ?.copyWith(color: notifier.value.allReseted ? Theme.of(context).dividerColor : null),
                onPressed: notifier.value.allReseted
                    ? null
                    : () {
                        notifier.value = notifier.value.resetTheme();
                        onThemeChanged(notifier.value);
                      },
              ),
            ];
          },
          builder: (callback) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(SpIcons.moreVert),
                  onPressed: callback,
                ),
              ],
            );
          },
        ),
        if (kIsCupertino) const CloseButton(),
      ],
    );
  }
}
