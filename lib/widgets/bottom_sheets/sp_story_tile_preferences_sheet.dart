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
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
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
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.9,
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
  late final simpleStory = _buildSimpleMockStory();

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
    final delta = Delta()
      ..insert(body)
      ..insert("\n")
      ..insert({"audio": "audio/mock_voice_1.m4a"})
      ..insert("\n")
      ..insert({"audio": "audio/mock_voice_2.m4a"});
    final now = DateTime.now();
    final story = StoryDbModel.fromDate(now);

    return story.copyWith(
      tags: tagIds,
      feeling: FeelingObject.feelignGroups.values.lastOrNull?.firstOrNull,
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

  static StoryDbModel _buildSimpleMockStory() {
    const body = "Grateful for a quiet morning.";
    final now = DateTime.now();
    final story = StoryDbModel.fromDate(now);

    return story.copyWith(
      feeling: FeelingObject.feelignGroups.values.firstOrNull?.firstOrNull,
      latestContent: story.latestContent!.copyWith(
        title: null,
        plainText: body,
        richPages: [
          StoryPageDbModel(
            id: now.millisecondsSinceEpoch + 10,
            title: null,
            body: (Delta()..insert(body)).toJson(),
            characterCount: body.length,
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
        title: Text(tr("list_tile.story_tile_preferences.title")),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (changed)
            IconButton(
              tooltip: tr("button.done"),
              icon: Icon(SpIcons.save, color: Theme.of(context).colorScheme.primary),
              onPressed: changed ? () => Navigator.maybePop(context, storyTilePreferences) : null,
            ),
          IconButton(
            icon: const Icon(SpIcons.refresh),
            onPressed: resettable ? () => setState(() => storyTilePreferences = defaultStoryTilePreferences) : null,
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        children: [
          SwitchListTile.adaptive(
            secondary: const Icon(SpIcons.timer),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            title: Text(tr("list_tile.show_time.title")),
            value: storyTilePreferences.showTime,
            onChanged: (value) {
              storyTilePreferences = storyTilePreferences.copyWith(showTime: value);
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(SpIcons.voice),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            title: Text(tr("list_tile.show_voice_count.title")),
            value: storyTilePreferences.showVoiceCount,
            onChanged: (value) {
              storyTilePreferences = storyTilePreferences.copyWith(showVoiceCount: value);
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(SpIcons.tag),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            title: Text(tr("list_tile.show_tag_labels.title")),
            value: storyTilePreferences.showTagLabels,
            onChanged: (value) {
              storyTilePreferences = storyTilePreferences.copyWith(showTagLabels: value);
              setState(() {});
            },
          ),
          SwitchListTile.adaptive(
            secondary: Icon(SpIcons.managingPage),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            title: Text(tr("list_tile.show_page_count.title")),
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
          const SizedBox(height: 16.0),
          SpSectionTitle(title: tr("general.preview")),
          AbsorbPointer(
            child: Column(
              children: [
                Stack(
                  children: [
                    const Positioned(
                      left: 32.0,
                      top: 0,
                      bottom: 0,
                      child: VerticalDivider(width: 1, indent: 32),
                    ),
                    SpStoryTile(
                      story: story,
                      preferences: storyTilePreferences,
                      showMonogram: true,
                      onTap: null,
                      listContext: context,
                      viewOnly: true,
                    ),
                  ],
                ),
                Stack(
                  children: [
                    const Positioned(
                      left: 32.0,
                      top: 0,
                      height: 16.0,
                      child: VerticalDivider(width: 1),
                    ),
                    SpStoryTile(
                      story: simpleStory,
                      preferences: storyTilePreferences,
                      showMonogram: false,
                      onTap: null,
                      listContext: context,
                      viewOnly: true,
                    ),
                  ],
                ),
              ],
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
          contentPadding: const EdgeInsets.only(left: 16.0, right: 24.0),
          leading: Icon(SpIcons.text),
          title: Text(tr("list_tile.preview_char_count.title")),
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
            min: 50,
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
