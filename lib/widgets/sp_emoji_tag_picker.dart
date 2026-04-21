import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

// ignore: constant_identifier_names
const _PADDING = 12.0;

class SpEmojiTagPicker extends StatefulWidget {
  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;
  final FutureOr<void> Function() close;

  const SpEmojiTagPicker({
    super.key,
    required this.initialTags,
    required this.onUpdated,
    required this.close,
  });

  @override
  State<SpEmojiTagPicker> createState() => _SpEmojiTagPicker();
}

class _SpEmojiTagPicker extends State<SpEmojiTagPicker> with DebounchedCallback {
  late Set<int> selectedTags = widget.initialTags.toSet();
  Map<TagCategoryDbModel, List<TagDbModel>>? emojisByCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await TagCategoryDbModel.db.getSuggestTagsByCategory(selectedTagIds: selectedTags);
    if (mounted) setState(() => emojisByCategory = result);
  }

  Future<void> _onToggle(TagDbModel tag) async {
    final entry = emojisByCategory?.entries.firstWhere((e) => e.key.id == tag.categoryId);
    final category = entry?.key;
    if (category == null) return;

    List<int> newTags;
    if (category.multiSelect) {
      newTags = selectedTags.contains(tag.id)
          ? ({...selectedTags}..remove(tag.id)).toList()
          : ({...selectedTags, tag.id}).toList();
    } else {
      if (selectedTags.contains(tag.id)) {
        newTags = ({...selectedTags}..remove(tag.id)).toList();
      } else {
        final others = emojisByCategory?[category]?.map((e) => e.id).where((id) => id != tag.id).toSet() ?? {};
        newTags =
            ({...selectedTags}
                  ..removeAll(others)
                  ..add(tag.id))
                .toList();
      }
    }

    setState(() => selectedTags = newTags.toSet());
    if (!tag.exist()) await tag.save();

    final success = await widget.onUpdated(newTags);
    if (!success) setState(() => selectedTags = widget.initialTags.toSet());

    debouncedCallback(_load);
  }

  Future<void> _onPickCustomEmoji(String emoji, TagCategoryDbModel category) async {
    // 1 emoji = 1 tag: deterministic ID guarantees no duplicates across categories.
    final tag = TagDbModel.emoji(emoji, categoryId: category.id);

    final isSelected = selectedTags.contains(tag.id);
    List<int> newTags;

    if (isSelected) {
      newTags = ({...selectedTags}..remove(tag.id)).toList();
    } else if (category.multiSelect) {
      newTags = ({...selectedTags, tag.id}).toList();
    } else {
      final others = emojisByCategory?[category]?.map((e) => e.id).where((id) => id != tag.id).toSet() ?? {};
      newTags =
          ({...selectedTags}
                ..removeAll(others)
                ..add(tag.id))
              .toList();
    }

    setState(() => selectedTags = newTags.toSet());

    // Persist logic:
    // - Suggested emojis (appear in any system category's suggestTags): preserve original categoryId.
    // - Custom (non-suggested) emojis that already exist: update categoryId to the tapped category.
    // - New emojis: save under the tapped category.
    final allSuggestedEmojis = TagCategoryDbModel.systemCategories
        .expand((c) => c.suggestTags().map((t) => t.emoji).whereType<String>())
        .toSet();
    final isSuggested = allSuggestedEmojis.contains(emoji);

    if (!tag.exist()) {
      await tag.save();
    } else if (!isSuggested) {
      // Custom emoji already exists in a different category — migrate it to the tapped category.
      final existing = await TagDbModel.db.find(tag.id);
      if (existing != null && existing.categoryId != category.id) {
        await TagDbModel.db.set(existing.copyWith(categoryId: category.id));
      }
    }

    final success = await widget.onUpdated(newTags);
    if (!success) setState(() => selectedTags = widget.initialTags.toSet());

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 288, maxHeight: 320),
      child: Material(
        clipBehavior: .hardEdge,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SpNestedNavigation(
          initialScreen: _buildMainPage(context),
        ),
      ),
    );
  }

  Widget _buildMainPage(BuildContext context) {
    if (emojisByCategory == null) return const SizedBox.shrink();

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: _PADDING),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 8.0,
          children: emojisByCategory!.entries.map((entry) {
            return _EmojiPicker(
              category: entry.key,
              tags: entry.value,
              selectedTags: selectedTags,
              onToggle: _onToggle,
              onPickCustomEmoji: (emoji) => _onPickCustomEmoji(emoji, entry.key),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  final TagCategoryDbModel category;
  final List<TagDbModel> tags;
  final Set<int> selectedTags;
  final Future<void> Function(TagDbModel) onToggle;
  final Future<void> Function(String emoji) onPickCustomEmoji;

  const _EmojiPicker({
    required this.category,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
    required this.onPickCustomEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 4.0,
      children: [
        SpSectionTitle(title: category.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _PADDING),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final itemCount = constraints.maxWidth ~/ 40;
              final itemWidth = constraints.maxWidth / itemCount - gap * (itemCount - 1) / itemCount;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  ...tags.map((tag) {
                    final isSelected = selectedTags.contains(tag.id);

                    return SpTapEffect(
                      scaleActive: 1.3,
                      effects: [.scaleDown],
                      onTap: () => onToggle(tag),
                      child: Container(
                        width: itemWidth,
                        height: itemWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? ColorScheme.of(context).surface.withValues(alpha: 0.5)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? ColorScheme.of(context).onSurface
                                : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1.0,
                          ),
                        ),
                        child: Text(tag.emoji ?? '', style: const TextStyle(fontSize: 22.0)),
                      ),
                    );
                  }),

                  // "+" button to open custom emoji picker
                  SpTapEffect(
                    scaleActive: 1.3,
                    effects: [.scaleDown],
                    onTap: () async {
                      final emoji = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const _CustomEmojiPicker()),
                      );
                      if (emoji != null) await onPickCustomEmoji(emoji);
                    },
                    child: Container(
                      width: itemWidth,
                      height: itemWidth,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        SpIcons.add,
                        size: itemWidth * 0.45,
                        color: ColorScheme.of(context).onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomEmojiPicker extends StatelessWidget {
  const _CustomEmojiPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const Padding(
          padding: EdgeInsets.all(4.0),
          child: BackButton(),
        ),
        Expanded(
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) => Navigator.of(context).pop(emoji.emoji),
            config: Config(
              emojiViewConfig: EmojiViewConfig(
                columns: 7,
                emojiSizeMax: 28.0,
                backgroundColor: ColorScheme.of(context).surface,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: ColorScheme.of(context).surfaceContainerHighest,
                indicatorColor: ColorScheme.of(context).primary,
                iconColor: ColorScheme.of(context).onSurface.withValues(alpha: 0.4),
                iconColorSelected: ColorScheme.of(context).primary,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: ColorScheme.of(context).surfaceContainerHighest,
                buttonIconColor: ColorScheme.of(context).onSurface,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}
