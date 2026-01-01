import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/rewards/rewards_view.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/views/settings/local_widgets/font_family_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_size_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_story_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_info_sheet.dart';
import 'package:storypad/widgets/sp_background_picker.dart';
import 'package:storypad/widgets/sp_cross_fade.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';
import 'package:storypad/widgets/story_list/local_widgets/story_tile_actions.dart';

enum SpStoryThemeBottomSheetPopAction {
  backToStoryList,
}

class SpStoryThemeBottomSheet extends BaseBottomSheet {
  final StoryPreferencesDbModel preferences;
  final BaseStoryViewModel? storyViewModel;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  SpStoryThemeBottomSheet({
    required this.preferences,
    required this.storyViewModel,
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
    return _StoryThemeSheet(
      preferences: preferences,
      storyViewModel: storyViewModel,
      onThemeChanged: onThemeChanged,
    );
  }
}

class _StoryThemeSheet extends StatefulWidget {
  final StoryPreferencesDbModel preferences;
  final BaseStoryViewModel? storyViewModel;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  const _StoryThemeSheet({
    required this.preferences,
    required this.storyViewModel,
    required this.onThemeChanged,
  });

  @override
  State<_StoryThemeSheet> createState() => _StoryThemeSheetState();
}

class _StoryThemeSheetState extends State<_StoryThemeSheet> with DebounchedCallback {
  late StoryPreferencesDbModel preferences = widget.preferences;

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
          const SizedBox(height: 4.0),
          const Divider(height: 1),
          const SizedBox(height: 8.0),
          SpBackgroundPicker(
            preferences: preferences,
            onThemeChanged: (preferences) async {
              setState(() {
                this.preferences = preferences;
              });

              debouncedCallback(() {
                widget.onThemeChanged(preferences);
              }, duration: Durations.medium1);
            },
          ),
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
        // Actions: move to bin/archive/put back are only available in read-only mode.
        // After completing an action, the page can be popped once to home/story list page.
        // If enabling these actions in edit mode, when popped, it pop to show story view which is not desired.
        // So disable these actions in edit mode for now. It's also make sense to not allow these actions during editing.

        BaseStoryViewModel? storyViewModel = widget.storyViewModel;
        StoryDbModel? story = storyViewModel?.story;

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
          if (storyViewModel != null && story != null) ...[
            SpPopMenuItem(
              title: tr('button.save_as_template'),
              leadingIconData: SpIcons.lightBulb,
              trailingIconData: !context.read<InAppPurchaseProvider>().template ? SpIcons.lock : null,
              titleStyle: context.read<InAppPurchaseProvider>().template
                  ? null
                  : TextStyle(color: Theme.of(context).disabledColor),
              onPressed: () => storyViewModel.saveAsTemplate(context),
            ),
            if (storyViewModel.readOnly && story.putBackAble)
              SpPopMenuItem(
                title: tr('button.put_back'),
                leadingIconData: SpIcons.putBack,
                onPressed: storyViewModel.readOnly
                    ? () async {
                        // StoryTileActions should only used when action will pop the page after action.
                        // Because it didn't notify its change to the view model. So not recommended to use it in any other case.
                        // StoryTile already listen to change by itself, that's why it is allowed to use [StoryTileActions]
                        bool putBack = await StoryTileActions(
                          story: story,
                          storyListReloaderContext: null,
                        ).putBack(context);

                        if (putBack && context.mounted) {
                          Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                        }
                      }
                    : null,
              ),
            if (storyViewModel.readOnly && story.archivable)
              SpPopMenuItem(
                title: tr('button.archive'),
                leadingIconData: SpIcons.archive,
                onPressed: storyViewModel.readOnly
                    ? () async {
                        // StoryTileActions should only used when action will pop the page after action.
                        // Because it didn't notify its change to the view model. So not recommended to use it in any other case.
                        // StoryTile already listen to change by itself, that's why it is allowed to use [StoryTileActions]
                        bool archived = await StoryTileActions(
                          story: story,
                          storyListReloaderContext: null,
                        ).archive(context);

                        if (archived && context.mounted) {
                          Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                        }
                      }
                    : null,
              ),
            if (storyViewModel.readOnly && story.canMoveToBin)
              SpPopMenuItem(
                title: tr('button.move_to_bin'),
                leadingIconData: SpIcons.delete,
                titleStyle: TextStyle(color: ColorScheme.of(context).error),
                onPressed: storyViewModel.readOnly
                    ? () async {
                        // StoryTileActions should only used when action will pop the page after action.
                        // Because it didn't notify its change to the view model. So not recommended to use it in any other case.
                        // StoryTile already listen to change by itself, that's why it is allowed to use [StoryTileActions]
                        bool moved = await StoryTileActions(
                          story: story,
                          storyListReloaderContext: null,
                        ).moveToBin(context);

                        if (moved && context.mounted) {
                          Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                        }
                      }
                    : null,
              ),
            if (storyViewModel.readOnly && story.hardDeletable)
              SpPopMenuItem(
                title: tr('button.permanent_delete'),
                leadingIconData: SpIcons.deleteForever,
                titleStyle: TextStyle(color: ColorScheme.of(context).error),
                onPressed: storyViewModel.readOnly
                    ? () async {
                        // StoryTileActions should only used when action will pop the page after action.
                        // Because it didn't notify its change to the view model. So not recommended to use it in any other case.
                        // StoryTile already listen to change by itself, that's why it is allowed to use [StoryTileActions]
                        bool deleted = await StoryTileActions(
                          story: story,
                          storyListReloaderContext: null,
                        ).hardDelete(context);

                        if (deleted && context.mounted) {
                          Navigator.pop(context, SpStoryThemeBottomSheetPopAction.backToStoryList);
                        }
                      }
                    : null,
              ),
            SpPopMenuItem(
              leadingIconData: SpIcons.info,
              title: tr("button.info"),
              onPressed: () => SpStoryInfoSheet(
                story: story,
                persisted: storyViewModel.flowType == EditingFlowType.update,
              ).show(context: context),
            ),
          ],
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
    BaseStoryViewModel? storyViewModel = widget.storyViewModel;
    StoryDbModel? story = storyViewModel?.story;

    List<Widget> startActions = [
      buildMoreOptionsButton(context),
      if (storyViewModel != null && story != null)
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(SpIcons.share),
              onPressed: () {
                if (storyViewModel.draftContent != null) {
                  SpShareStoryBottomSheet(
                    story: story,
                    draftContent: storyViewModel.draftContent!,
                    pagesManager: storyViewModel.pagesManager,
                  ).show(context: context);
                }
              },
            );
          },
        ),
      SpFadeIn.bound(
        child: IconButton(
          onPressed: () => context.read<DevicePreferencesProvider>().toggleThemeMode(context),
          icon: SpThemeModeIcon(parentContext: context),
        ),
      ),
    ];

    bool showWordCount =
        storyViewModel != null &&
        widget.storyViewModel?.draftContent?.wordCount != null &&
        widget.storyViewModel?.draftContent?.characterCount != null;

    if (kIsCupertino) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: startActions),
          if (showWordCount)
            Expanded(
              child: Align(
                alignment: .centerRight,
                child: _WordCharCountButton(storyViewModel: storyViewModel),
              ),
            ),
          const CloseButton(),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: showWordCount ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          if (showWordCount)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8.0),
                alignment: .centerLeft,
                child: _WordCharCountButton(storyViewModel: storyViewModel),
              ),
            ),
          Row(children: startActions.reversed.toList()),
        ],
      );
    }
  }
}

class _WordCharCountButton extends StatefulWidget {
  const _WordCharCountButton({
    required this.storyViewModel,
  });

  final BaseStoryViewModel? storyViewModel;

  @override
  State<_WordCharCountButton> createState() => _WordCharCountButtonState();
}

class _WordCharCountButtonState extends State<_WordCharCountButton> {
  bool showingWords = true;

  @override
  Widget build(BuildContext context) {
    final rewarded = context.read<InAppPurchaseProvider>().writingStats;

    if (!rewarded) {
      return TextButton.icon(
        icon: const Icon(SpIcons.lock),
        label: Text(tr('button.unlock_writing_stats')),
        onPressed: () => const RewardsRoute(initialFocusedRewardFeature: .writing_stats).push(context),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
      icon: Icon(SpIcons.text),
      label: SpCrossFade(
        showFirst: showingWords,
        firstChild: Text(
          tr(
            'general.word_count_args',
            namedArgs: {
              'WORDS_COUNT': (widget.storyViewModel?.draftContent?.wordCount ?? 0).toString(),
            },
          ),
        ),
        secondChild: Text(
          tr(
            'general.character_count_args',
            namedArgs: {
              'CHAR_COUNT': rewarded ? (widget.storyViewModel?.draftContent?.characterCount ?? 0).toString() : '---',
            },
          ),
        ),
      ),
      onPressed: () {
        setState(() {
          showingWords = !showingWords;
        });
      },
    );
  }
}
