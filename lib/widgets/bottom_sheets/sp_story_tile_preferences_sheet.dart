import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/story_list/sp_story_tile.dart';

class SpStoryTilePreferencesSheet extends BaseBottomSheet {
  const SpStoryTilePreferencesSheet();

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView(context, bottomPadding);
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: maxChildSize,
        maxChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(context, bottomPadding),
          );
        },
      );
    }
  }

  Widget buildView(BuildContext context, double bottomPadding) {
    return _StoryTilePreferencesSheetContent(
      bottomPadding: bottomPadding,
    );
  }
}

class _StoryTilePreferencesSheetContent extends StatefulWidget {
  const _StoryTilePreferencesSheetContent({
    required this.bottomPadding,
  });

  final double bottomPadding;

  @override
  State<_StoryTilePreferencesSheetContent> createState() => _StoryTilePreferencesSheetContentState();
}

class _StoryTilePreferencesSheetContentState extends State<_StoryTilePreferencesSheetContent> {
  late var storyTilePreferences = context.read<DevicePreferencesProvider>().preferences.storyTilePreferences;
  late var defaultStoryTilePreferences = StoryTilePreferencesObject();
  late var initialStoryTilePreferences = storyTilePreferences;

  late final firstTag = context.read<TagsProvider>().tags?.items.firstOrNull;
  late final tagIds = firstTag != null ? [firstTag!.id.toString()] : null;
  late final story = _buildMockStory(tagIds: tagIds);

  bool get changed => jsonEncode(storyTilePreferences.toJson()) != jsonEncode(initialStoryTilePreferences.toJson());
  bool get resettable => jsonEncode(storyTilePreferences.toJson()) != jsonEncode(defaultStoryTilePreferences.toJson());

  static StoryDbModel _buildMockStory({List<String>? tagIds}) {
    const body =
        "Today was a wonderful day. I spent time reading a good book "
        "and took a long walk in the park. The weather was perfect "
        "and I felt grateful for all the little things in life. "
        "In the evening, I called an old friend and we laughed about memories "
        "from years ago. These small moments remind me how beautiful life truly is. "
        "Tomorrow I plan to wake up early, journal, and enjoy a slow morning "
        "with a warm cup of coffee before diving into work.";
    final delta = Delta()..insert(body);
    final now = DateTime.now();
    final story = StoryDbModel.fromDate(now);

    return story.copyWith(
      tags: tagIds,
      latestContent: story.latestContent!.copyWith(
        title: "My Journal Entry ✨",
        plainText: body,
        richPages: [
          StoryPageDbModel(
            id: now.millisecondsSinceEpoch,
            title: "My Journal Entry ✨",
            body: delta.toJson(),
            characterCount: body.length,
            wordCount: null,
          ),
          StoryPageDbModel(
            id: now.millisecondsSinceEpoch + 1,
            title: null,
            body: (Delta()..insert("Page two content.")).toJson(),
            characterCount: null,
            wordCount: null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("List Style"),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (resettable)
            IconButton(
              icon: const Icon(SpIcons.refresh),
              onPressed: () => setState(() => storyTilePreferences = defaultStoryTilePreferences),
            ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: changed,
        child: SpFadeIn.fromBottom(
          child: Column(
            mainAxisSize: .min,
            children: [
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ).add(EdgeInsets.only(bottom: widget.bottomPadding)),
                child: FilledButton.icon(
                  label: const Text("Save"),
                  onPressed: () => Navigator.maybePop(context, storyTilePreferences),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        children: [
          const SizedBox(height: 8.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: const Icon(SpIcons.timer),
                  contentPadding: const EdgeInsets.only(left: 20.0, right: 12.0),
                  title: Text(tr("list_tile.story_tile_preferences.show_time")),
                  value: storyTilePreferences.showTime,
                  onChanged: (value) {
                    storyTilePreferences = storyTilePreferences.copyWith(showTime: value);
                    setState(() {});
                  },
                ),
                SwitchListTile.adaptive(
                  secondary: Icon(SpIcons.voice),
                  contentPadding: const EdgeInsets.only(left: 20.0, right: 12.0),
                  title: Text(tr("list_tile.story_tile_preferences.show_voice_count")),
                  value: storyTilePreferences.showVoiceCount,
                  onChanged: (value) {
                    storyTilePreferences = storyTilePreferences.copyWith(showVoiceCount: value);
                    setState(() {});
                  },
                ),
                SwitchListTile.adaptive(
                  secondary: const Icon(SpIcons.tag),
                  contentPadding: const EdgeInsets.only(left: 20.0, right: 12.0),
                  title: Text(tr("list_tile.story_tile_preferences.show_tag_labels")),
                  value: storyTilePreferences.showTagLabels,
                  onChanged: (value) {
                    storyTilePreferences = storyTilePreferences.copyWith(showTagLabels: value);
                    setState(() {});
                  },
                ),
                SwitchListTile.adaptive(
                  secondary: Icon(SpIcons.managingPage),
                  contentPadding: const EdgeInsets.only(left: 20.0, right: 12.0),
                  title: Text(tr("list_tile.story_tile_preferences.show_page_count")),
                  value: storyTilePreferences.showPageCount,
                  onChanged: (value) {
                    storyTilePreferences = storyTilePreferences.copyWith(showPageCount: value);
                    setState(() {});
                  },
                ),
                _CharacterCountSlider(
                  preferences: storyTilePreferences,
                  onChanged: (value) {
                    storyTilePreferences = storyTilePreferences.copyWith(displayCharacterCount: value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          const SpSectionTitle(title: "Preview"),
          AbsorbPointer(
            child: SpStoryTile(
              story: story,
              preferences: storyTilePreferences,
              showMonogram: true,
              onTap: null,
              listContext: context,
              viewOnly: true,
            ),
          ),
          SizedBox(height: widget.bottomPadding),
        ],
      ),
    );
  }
}

class _CharacterCountSlider extends StatefulWidget {
  const _CharacterCountSlider({
    required this.preferences,
    required this.onChanged,
  });

  final StoryTilePreferencesObject preferences;
  final void Function(int value) onChanged;

  @override
  State<_CharacterCountSlider> createState() => _CharacterCountSliderState();
}

class _CharacterCountSliderState extends State<_CharacterCountSlider> {
  late int _localValue = widget.preferences.displayCharacterCount;

  @override
  void didUpdateWidget(_CharacterCountSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.displayCharacterCount != widget.preferences.displayCharacterCount) {
      _localValue = widget.preferences.displayCharacterCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 20.0, right: 24.0),
          leading: Icon(SpIcons.text),
          title: Text(tr("list_tile.story_tile_preferences.display_character_count")),
          trailing: Text(
            _localValue.toString(),
            style: TextTheme.of(context).bodyMedium?.copyWith(
              color: ColorScheme.of(context).primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider.adaptive(
            value: _localValue.toDouble(),
            min: 0,
            max: 500,
            label: _localValue.toString(),
            onChanged: (value) {
              setState(() => _localValue = value.toInt());
              widget.onChanged(_localValue);
            },
          ),
        ),
      ],
    );
  }
}
