import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/font_weight_extension.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
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

  DefaultStoryPreferencesObject get _currentThemeAsDefaultStoryPreferences {
    return DefaultStoryPreferencesObject(
      defaultColorSeedValue: preferences.colorSeedValue,
      defaultColorTone: preferences.colorTone,
      defaultBackgroundImagePath: preferences.backgroundImagePath,
      defaultLayoutType: preferences.layoutType,
    );
  }

  bool get _currentThemeAlreadySavedAsDefault {
    final currentDefaults = context.read<DevicePreferencesProvider>().preferences.defaultStoryPreferences;
    final currentThemeAsDefault = _currentThemeAsDefaultStoryPreferences;

    return currentDefaults.defaultColorSeedValue == currentThemeAsDefault.defaultColorSeedValue &&
        currentDefaults.defaultColorTone == currentThemeAsDefault.defaultColorTone &&
        currentDefaults.defaultBackgroundImagePath == currentThemeAsDefault.defaultBackgroundImagePath &&
        currentDefaults.defaultLayoutType == currentThemeAsDefault.defaultLayoutType;
  }

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
            weekday: 2,
          ),
          FontSizeTile(
            currentFontSize: preferences.fontSize,
            onChanged: (fontSize) {
              preferences = preferences.copyWith(fontSize: fontSize);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
            weekday: 1,
          ),
          FontWeightTile(
            currentFontWeight:
                preferences.fontWeight ?? context.read<DevicePreferencesProvider>().preferences.fontWeight,
            onChanged: (value) {
              preferences = preferences.copyWith(fontWeightIndex: value.weightIndex);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
            weekday: 3,
          ),
          const SizedBox(height: 8.0),
          SpBackgroundPicker(
            backgroundColor: ColorScheme.of(context).surfaceContainerLow,
            colorSeedValue: preferences.colorSeedValue,
            colorTone: preferences.colorTone,
            backgroundImagePath: preferences.backgroundImagePath,
            onThemeChanged: ({int? colorSeedValue, int? colorTone, String? backgroundImagePath}) async {
              setState(() {
                preferences = preferences.copyWith(
                  colorSeedValue: colorSeedValue,
                  colorTone: colorTone,
                  backgroundImagePath: backgroundImagePath,
                );
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
        final alreadySavedAsDefault = _currentThemeAlreadySavedAsDefault;

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
          SpPopMenuItem(
            title: tr('button.save_as_default'),
            leadingIconData: SpIcons.theme,
            titleStyle: TextStyle(
              color: alreadySavedAsDefault ? Theme.of(context).disabledColor : null,
            ),
            trailingIconData: !context.read<InAppPurchaseProvider>().isProUser
                ? SpIcons.lock
                : (alreadySavedAsDefault ? SpIcons.check : null),
            onPressed: !context.read<InAppPurchaseProvider>().isProUser
                ? () => const PaywallRoute(initialFocus: .customizations).push(context)
                : alreadySavedAsDefault
                ? null
                : () {
                    context.read<DevicePreferencesProvider>().setDefaultStoryPreferences(
                      _currentThemeAsDefaultStoryPreferences,
                    );
                    MessengerService.of(context).showSnackBar(tr("snack_bar.save_theme_as_default_success"));
                    setState(() {});
                  },
          ),
          if (storyViewModel != null && story != null) ...[
            SpPopMenuItem(
              title: tr('button.save_as_template'),
              leadingIconData: SpIcons.lightBulb,
              trailingIconData: !context.read<InAppPurchaseProvider>().isProUser ? SpIcons.lock : null,
              onPressed: () => storyViewModel.saveAsTemplate(context),
            ),
            if (story.editable)
              SpPopMenuItem(
                title: story.pinned == true ? tr('button.unpin_story') : tr('button.pin_story'),
                leadingIconData: story.pinned == true ? SpIcons.pinSlash : SpIcons.pin,
                onPressed: () => storyViewModel.togglePinned(),
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
          onPressed: () async {
            await context.read<DevicePreferencesProvider>().toggleThemeMode(context);
            if (!context.mounted) return;

            // for android, sheet replacement to apply theme mode immediately.
            // otherwise, just skip.
            if (kIsCupertino) return;

            SpStoryThemeBottomSheet(
              onThemeChanged: widget.onThemeChanged,
              preferences: preferences,
              storyViewModel: storyViewModel,
            ).showReplacement(context: HomeView.homeContext!);
          },
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
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
      icon: const Icon(SpIcons.text),
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
              'CHAR_COUNT': (widget.storyViewModel?.draftContent?.characterCount ?? 0).toString(),
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
