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
import 'package:storypad/views/theme/local_widgets/font_size_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_story_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_info_sheet.dart';
import 'package:storypad/widgets/sp_color_list_selector.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';

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
            currentFontWeight: preferences.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
            currentFontFamily: preferences.fontFamily ?? context.read<ThemeProvider>().theme.fontFamily,
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
            currentFontWeight: preferences.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
            onChanged: (value) {
              preferences = preferences.copyWith(fontWeightIndex: value.index);
              setState(() {});

              widget.onThemeChanged(preferences);
            },
          ),
          ListTile(
            leading: Icon(SpIcons.book),
            title: Text(tr("button.manage_pages")),
            subtitle: Text(plural('plural.page', widget.draftContent?.richPages?.length ?? 0)),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () async {
              await Navigator.maybePop(context);
              FocusManager.instance.primaryFocus?.unfocus();
              widget.viewModel.pagesManager.toggleManagingPage();
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
        return [
          SpPopMenuItem(
            leadingIconData: SpIcons.info,
            title: tr("button.info"),
            onPressed: () => SpStoryInfoSheet(
              story: widget.viewModel.story!,
              persisted: widget.viewModel.flowType == EditingFlowType.update,
            ).show(context: context),
          ),
          SpPopMenuItem(
            leadingIconData: SpIcons.refresh,
            title: tr("button.reset_theme"),
            titleStyle: TextTheme.of(context)
                .bodyMedium
                ?.copyWith(color: preferences.allReseted ? Theme.of(context).dividerColor : null),
            onPressed: preferences.allReseted
                ? null
                : () {
                    preferences = preferences.resetTheme();
                    setState(() {});

                    widget.onThemeChanged(preferences);
                  },
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
        onPressed: () => context.read<ThemeProvider>().toggleThemeMode(context),
        icon: SpThemeModeIcon(parentContext: context),
      ),
      Builder(builder: (context) {
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
      }),
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
