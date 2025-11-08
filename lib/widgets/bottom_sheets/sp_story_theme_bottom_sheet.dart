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
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/views/settings/local_widgets/font_family_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_size_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_story_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_info_sheet.dart';
import 'package:storypad/widgets/sp_color_list_selector.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';
import 'package:storypad/widgets/story_list/local_widgets/story_tile_actions.dart';

enum SpStoryThemeBottomSheetPopAction {
  backToStoryList,
}

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
    return StoryThemeSheet(
      story: story,
      draftContent: draftContent,
      viewModel: viewModel,
      onThemeChanged: onThemeChanged,
    );
  }
}

class StoryThemeSheet extends StatefulWidget {
  final StoryDbModel story;
  final StoryContentDbModel? draftContent;
  final BaseStoryViewModel viewModel;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  const StoryThemeSheet({
    super.key,
    required this.story,
    this.draftContent,
    required this.viewModel,
    required this.onThemeChanged,
  });

  @override
  State<StoryThemeSheet> createState() => _StoryThemeSheetState();
}

class _StoryThemeSheetState extends State<StoryThemeSheet> {
  late StoryPreferencesDbModel preferences = widget.story.preferences;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4.0),
          buildHeader(context),
          const SizedBox(height: 8.0),
          SpColorListSelector(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            selectedColor: preferences.colorSeed,
            colorTone: preferences.colorToneFallback,
            onChanged: (color, colorTone) {
              preferences = preferences.copyWith(colorSeedValue: color?.value, colorTone: colorTone);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          const SizedBox(height: 8.0),

          // This give more problem on navigation.
          // Let's disable it for now.
          //
          // ThemeModeTile(
          //   currentThemeMode: theme.themeMode ?? ThemeMode.system,
          //   onChanged: (ThemeMode themeMode) {
          //     preferences = preferences.copyWith(themeMode: themeMode);
          //     onThemeChanged(preferences);
          //   },
          // ),
          FontFamilyTile(
            currentFontWeight:
                preferences.fontWeight ?? context.read<DevicePreferencesProvider>().preferences.fontWeight,
            currentFontFamily:
                preferences.fontFamily ?? context.read<DevicePreferencesProvider>().preferences.fontFamily,
            onChanged: (fontFamily) {
              preferences = preferences.copyWith(fontFamily: fontFamily);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          FontSizeTile(
            currentFontSize: preferences.fontSize,
            onChanged: (fontSize) {
              preferences = preferences.copyWith(fontSize: fontSize);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          FontWeightTile(
            currentFontWeight:
                preferences.fontWeight ?? context.read<DevicePreferencesProvider>().preferences.fontWeight,
            onChanged: (value) {
              preferences = preferences.copyWith(fontWeightIndex: value.index);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: 12.0),
          SpLayoutTypeSection(
            selected: preferences.layoutType,
            onThemeChanged: (layoutType) {
              preferences = preferences.copyWith(layoutType: layoutType);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          const SizedBox(height: 8.0),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget buildMoreOptionsButton(BuildContext context) {
    return SpPopupMenuButton(
      dyGetter: (dy) => dy + 56,
      items: (context) {
        final story = widget.viewModel.story;
        if (story == null) return [];

        // Actions: move to bin/archive/put back are only available in read-only mode.
        // After completing an action, the page can be popped once to home/story list page.
        // If enabling these actions in edit mode, when popped, it pop to show story view which is not desired.
        // So disable these actions in edit mode for now. It's also make sense to not allow these actions during editing.
        return [
          SpPopMenuItem(
            leadingIconData: SpIcons.refresh,
            title: tr("button.reset_theme"),
            titleStyle: TextStyle(color: preferences.allReseted ? Theme.of(context).disabledColor : null),
            onPressed: preferences.allReseted
                ? null
                : () {
                    preferences = preferences.resetTheme();
                    setState(() {});

                    widget.onThemeChanged(preferences);
                  },
          ),
          if (widget.viewModel.readOnly && story.putBackAble)
            SpPopMenuItem(
              title: tr('button.put_back'),
              leadingIconData: SpIcons.putBack,
              onPressed: widget.viewModel.readOnly
                  ? () {
                      StoryTileActions(story: story, storyListReloaderContext: null).putBack(context);
                      Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                    }
                  : null,
            ),
          if (widget.viewModel.readOnly && story.archivable)
            SpPopMenuItem(
              title: tr('button.archive'),
              leadingIconData: SpIcons.archive,
              onPressed: widget.viewModel.readOnly
                  ? () {
                      StoryTileActions(story: story, storyListReloaderContext: null).archive(context);
                      Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                    }
                  : null,
            ),
          if (widget.viewModel.readOnly && story.canMoveToBin)
            SpPopMenuItem(
              title: tr('button.move_to_bin'),
              leadingIconData: SpIcons.delete,
              titleStyle: TextStyle(color: ColorScheme.of(context).error),
              onPressed: widget.viewModel.readOnly
                  ? () {
                      StoryTileActions(story: story, storyListReloaderContext: null).moveToBin(context);
                      Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                    }
                  : null,
            ),
          if (widget.viewModel.readOnly && story.hardDeletable)
            SpPopMenuItem(
              title: tr('button.permanent_delete'),
              leadingIconData: SpIcons.deleteForever,
              titleStyle: TextStyle(color: ColorScheme.of(context).error),
              onPressed: widget.viewModel.readOnly
                  ? () async {
                      await StoryTileActions(story: story, storyListReloaderContext: null).hardDelete(context);
                      if (context.mounted) Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                    }
                  : null,
            ),
          SpPopMenuItem(
            leadingIconData: SpIcons.info,
            title: tr("button.info"),
            onPressed: () => SpStoryInfoSheet(
              story: widget.viewModel.story!,
              persisted: widget.viewModel.flowType == EditingFlowType.update,
            ).show(context: context),
          ),
        ];
      },
      builder: (callback) {
        return IconButton(
          icon: const Icon(SpIcons.moreVert),
          onPressed: callback,
        );
      },
    );
  }

  Widget buildHeader(BuildContext context) {
    List<Widget> actions = [
      buildMoreOptionsButton(context),
      IconButton(
        onPressed: () {
          if (kIsCupertino) {
            context.read<DevicePreferencesProvider>().toggleThemeMode(context);
          } else {
            context.read<DevicePreferencesProvider>().toggleThemeMode(
              context,
              delay: const Duration(milliseconds: 300),
            );
            // TODO: fix material modal to dynamic base on theme mode instead of pop
            Navigator.maybePop(context);
          }
        },
        icon: SpThemeModeIcon(parentContext: context),
      ),
      Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(SpIcons.share),
            onPressed: () {
              if (widget.viewModel.story != null && widget.viewModel.draftContent != null) {
                SpShareStoryBottomSheet(
                  story: widget.viewModel.story!,
                  draftContent: widget.viewModel.draftContent!,
                  pagesManager: widget.viewModel.pagesManager,
                ).show(context: context);
              }
            },
          );
        },
      ),
    ];

    if (!kIsCupertino) actions = actions.reversed.toList();

    return Row(
      mainAxisAlignment: kIsCupertino ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      children: [
        Row(children: actions),
        if (kIsCupertino) const CloseButton(),
      ],
    );
  }
}
