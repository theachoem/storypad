import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorScheme.of(context).surfaceContainerHighest,
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 288, maxHeight: 320),
        child: _buildContents(),
      ),
    );
  }

  Widget _buildContents() {
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

  const _EmojiPicker({
    required this.category,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
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
                children: tags.map((tag) {
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
                        color: isSelected ? ColorScheme.of(context).surface.withValues(alpha: 0.5) : Colors.transparent,
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
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
