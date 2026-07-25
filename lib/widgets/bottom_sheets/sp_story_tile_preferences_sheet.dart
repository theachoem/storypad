import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';
import 'package:storypad/widgets/story_list/sp_story_tile.dart';

class SpStoryTilePreferencesSheet extends BaseBottomSheet {
  const SpStoryTilePreferencesSheet({this.onChanged});

  /// Reports the live draft on every change ([null] when nothing differs from
  /// the saved value). The caller commits it after the sheet closes, so the
  /// global preferences only change once — avoiding story list jank mid-sheet.
  final void Function(StoryTilePreferencesObject? preferences)? onChanged;

  @override
  bool get fullScreen => true;

  @override
  Future<T?> show<T>({required BuildContext context, bool useRootNavigator = false}) async {
    await _StoryTilePreferencesSheetContentState._ensureDemoFeelingTag();
    if (!context.mounted) return null;
    return super.show(context: context, useRootNavigator: useRootNavigator);
  }

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
      onChanged: onChanged,
    );
  }
}

class _StoryTilePreferencesSheetContent extends StatefulWidget {
  const _StoryTilePreferencesSheetContent({
    required this.bottomPadding,
    this.onChanged,
  });

  final double bottomPadding;
  final void Function(StoryTilePreferencesObject? preferences)? onChanged;

  @override
  State<_StoryTilePreferencesSheetContent> createState() => _StoryTilePreferencesSheetContentState();
}

class _StoryTilePreferencesSheetContentState extends State<_StoryTilePreferencesSheetContent> {
  late var storyTilePreferences = context.read<DevicePreferencesProvider>().preferences.storyTilePreferences;
  late var defaultStoryTilePreferences = StoryTilePreferencesObject();
  late var initialStoryTilePreferences = storyTilePreferences;

  // Ensure a demo feeling emoji tag exists. ID is deterministic so we can use it
  // immediately without waiting for the DB write.
  static TagDbModel get _demoFeeling1Tag => TagCategoryDbModel.feeling().suggestTags()[8];
  static TagDbModel get _demoFeeling2Tag => TagCategoryDbModel.feeling().suggestTags()[7];
  static TagDbModel get _demoActivityTag => TagCategoryDbModel.activity().suggestTags()[1];

  static Future<void> _ensureDemoFeelingTag() async {
    if (!TagDbModel.db.exist(_demoFeeling1Tag.id)) await TagDbModel.db.set(_demoFeeling1Tag);
    if (!TagDbModel.db.exist(_demoFeeling2Tag.id)) await TagDbModel.db.set(_demoFeeling2Tag);
    if (!TagDbModel.db.exist(_demoActivityTag.id)) await TagDbModel.db.set(_demoActivityTag);
  }

  late StoryDbModel story = _buildMockStory();
  late final simpleStory = _buildSimpleMockStory();

  final ScrollController _optionsScrollController = ScrollController();

  // Real image paths sampled from the user's assets so the preview can demo the
  // photo collage. Empty when the user has no images yet.
  List<String> _previewImagePaths = [];

  bool get changed => jsonEncode(storyTilePreferences.toJson()) != jsonEncode(initialStoryTilePreferences.toJson());
  bool get resettable => jsonEncode(storyTilePreferences.toJson()) != jsonEncode(defaultStoryTilePreferences.toJson());

  void _apply(StoryTilePreferencesObject next) {
    setState(() => storyTilePreferences = next);
    widget.onChanged?.call(changed ? storyTilePreferences : null);
  }

  @override
  void initState() {
    super.initState();
    _ensureDemoFeelingTag();
    _loadPreviewImages();
  }

  @override
  void dispose() {
    _optionsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviewImages() async {
    final collection = await AssetDbModel.db.where(
      filters: {
        'types': [AssetType.image, AssetType.video],
        'limit': 3,
      },
    );

    final images = collection?.items.map((e) => e.relativeLocalFilePath).toList();
    if (images == null || images.isEmpty || !mounted) return;

    setState(() {
      _previewImagePaths = images;
      story = _buildMockStory();
    });
  }

  StoryDbModel _buildMockStory() {
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
      ..insert("\n");
    if (_previewImagePaths.isNotEmpty) {
      delta
        ..insert({"image": _previewImagePaths.join('|')})
        ..insert("\n");
    }
    delta
      ..insert({"audio": "audio/mock_voice_1.m4a"})
      ..insert("\n")
      ..insert({"audio": "audio/mock_voice_2.m4a"});
    final now = DateTime.now();
    final story = StoryDbModel.fromDate(now);

    return story.copyWith(
      tags: [
        ?context.read<TagsProvider>().tags?.items.firstOrNull?.id.toString(),
        ?context.read<TagsProvider>().peopleTags?.items.firstOrNull?.id.toString(),
        _demoFeeling2Tag.id.toString(),
      ],
      feeling: null,
      place: PlaceDbModel(
        latitude: 0.0,
        longitude: 0.0,
        placeName: "Home",
        country: "Cambodia",
        locality: "Phnom Penh",
        address: "123 Main St, Phnom Penh, Cambodia",
      ),
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

  StoryDbModel _buildSimpleMockStory() {
    const body = "Grateful for a quiet morning.";
    final now = DateTime.now();
    final story = StoryDbModel.fromDate(now);
    final tags = [
      _demoFeeling1Tag.id.toString(),
      _demoActivityTag.id.toString(),
    ];

    return story.copyWith(
      tags: tags,
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
          // Pro users save automatically when the sheet closes, so no save button.
          // Non-pro users keep a locked save button that opens the paywall; they can
          // still preview changes but cannot persist them.
          if (changed && !Provider.of<InAppPurchaseProvider>(context).isProUser)
            IconButton(
              tooltip: tr("button.done"),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(SpIcons.save, color: Theme.of(context).colorScheme.primary),
                  const Positioned(
                    top: -2,
                    right: -8,
                    child: Icon(SpIcons.lock, size: 12.0),
                  ),
                ],
              ),
              onPressed: () => const PaywallRoute(initialFocus: .customizations).push(context),
            ),
          IconButton(
            icon: const Icon(SpIcons.refresh),
            onPressed: resettable ? () => _apply(defaultStoryTilePreferences) : null,
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        padding: const EdgeInsets.only(top: 8.0),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              height: 240,
              child: Scrollbar(
                controller: _optionsScrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _optionsScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 7, icon: SpIcons.photo),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.photo_collage.title")),
                      value: storyTilePreferences.photoCollage,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(photoCollage: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 1, icon: SpIcons.timer),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_time.title")),
                      value: storyTilePreferences.showTime,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showTime: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 2, icon: SpIcons.voice),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_voice_count.title")),
                      value: storyTilePreferences.showVoiceCount,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showVoiceCount: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 3, icon: SpIcons.tag),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_tag_labels.title")),
                      value: storyTilePreferences.showTagLabels,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showTagLabels: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 4, icon: SpIcons.alternateEmail),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_people_labels.title")),
                      value: storyTilePreferences.showPeopleLabels,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showPeopleLabels: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 5, icon: SpIcons.managingPage),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_page_count.title")),
                      value: storyTilePreferences.showPageCount,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showPageCount: value)),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const SpSettingIconBadge(weekday: 6, icon: SpIcons.map),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 14.0),
                      title: Text(tr("list_tile.show_location.title")),
                      value: storyTilePreferences.showLocation,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(showLocation: value)),
                    ),
                    _CharacterCountSlider(
                      preferences: storyTilePreferences,
                      onChanged: (value) => _apply(storyTilePreferences.copyWith(displayCharacterCount: value)),
                    ),
                  ],
                ),
              ),
            ),
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
          contentPadding: const EdgeInsets.only(left: 16.0, right: 32.0),
          leading: const SpSettingIconBadge(weekday: 1, icon: SpIcons.text),
          title: Text(tr("list_tile.preview_char_count.title")),
          trailing: Text(
            _localValue.toString(),
            style: TextTheme.of(context).bodyMedium?.copyWith(
              color: ColorScheme.of(context).primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
