part of '../sp_story_labels_sheet.dart';

/// Emoji tags (feelings, activities, …), one section per category; "+" opens the
/// full emoji picker as a second sheet ([_CustomEmojiSheet]).
class _StickersTab extends StatefulWidget {
  const _StickersTab({
    required this.selectedTags,
    required this.onToggle,
  });

  final Set<int> selectedTags;
  final Future<void> Function(int id, {Iterable<int> exclusiveWith}) onToggle;

  @override
  State<_StickersTab> createState() => _StickersTabState();
}

class _StickersTabState extends State<_StickersTab> with DebounchedCallback {
  Map<TagCategoryDbModel, List<TagDbModel>>? emojisByCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await TagCategoryDbModel.db.getSuggestTagsByCategory(selectedTagIds: widget.selectedTags);
    if (mounted) setState(() => emojisByCategory = result);
  }

  // Single-select categories keep at most one of their emojis on the story.
  Future<void> _toggle(TagDbModel tag, TagCategoryDbModel category) {
    return widget.onToggle(
      tag.id,
      exclusiveWith: category.multiSelect ? const [] : [for (final e in emojisByCategory?[category] ?? []) e.id],
    );
  }

  // Toggled after any save, from the sheet's latest set: a quick second tap meanwhile isn't lost.
  Future<void> _onToggle(TagDbModel tag, TagCategoryDbModel category) async {
    if (!tag.exist()) await tag.save();
    if (!mounted) return;

    await _toggle(tag, category);
    debouncedCallback(_load);
  }

  Future<void> _onPickCustomEmoji(String emoji, TagCategoryDbModel category) async {
    // 1 emoji = 1 tag: deterministic ID guarantees no duplicates across categories.
    final tag = TagDbModel.emoji(emoji, categoryId: category.id);

    // Persist logic:
    // - Suggested emojis (appear in any system category's suggestTags): preserve original categoryId.
    // - Custom (non-suggested) emojis that already exist: update categoryId to the tapped category.
    // - New emojis: save under the tapped category.
    final isSuggested = TagCategoryDbModel.systemCategories.any((c) => c.suggestTags().any((t) => t.emoji == emoji));

    if (!tag.exist()) {
      await tag.save();
    } else if (!isSuggested) {
      final existing = await TagDbModel.db.find(tag.id);
      if (existing != null && existing.categoryId != category.id) {
        await TagDbModel.db.set(existing.copyWith(categoryId: category.id));
      }
    }

    if (!mounted) return;
    await _toggle(tag, category);
    _load();
  }

  Future<void> _openCustomEmojiPicker(TagCategoryDbModel category) async {
    final preferredCategory = await PreferredEmojiTabStorage().getCategoryFor(category.id);
    if (!mounted) return;

    final emoji = await _CustomEmojiSheet(
      category: category,
      initialCategory: preferredCategory,
    ).show<String>(context: context);

    if (emoji != null) await _onPickCustomEmoji(emoji, category);
  }

  @override
  Widget build(BuildContext context) {
    if (emojisByCategory == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        // The sheet's safe area (see SpStoryLabelsSheet): emojis scroll under it.
        padding: EdgeInsets.only(bottom: 16.0 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 12.0,
          children: [
            for (final entry in emojisByCategory!.entries)
              _EmojiSection(
                category: entry.key,
                tags: entry.value,
                selectedTags: widget.selectedTags,
                onToggle: (tag) => _onToggle(tag, entry.key),
                onAdd: () => _openCustomEmojiPicker(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiSection extends StatelessWidget {
  const _EmojiSection({
    required this.category,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
    required this.onAdd,
  });

  final TagCategoryDbModel category;
  final List<TagDbModel> tags;
  final Set<int> selectedTags;
  final void Function(TagDbModel tag) onToggle;
  final void Function() onAdd;

  @override
  Widget build(BuildContext context) {
    // Each row keeps clear of the sheet's side insets; the scroll view and its scrollbar span the full width.
    return Column(
      crossAxisAlignment: .start,
      spacing: 6.0,
      children: [
        _SideInset(
          minimum: 17.0,
          child: SpSectionTitle(title: category.title, padding: EdgeInsets.zero),
        ),
        _SideInset(
          minimum: 16.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // As many cells as fit at 45pt or more (6–7 per row on phones).
              const gap = 6.0;
              const minItemWidth = 45.0;
              final itemCount = (constraints.maxWidth + gap) ~/ (minItemWidth + gap);
              final itemWidth = (constraints.maxWidth - gap * (itemCount - 1)) / itemCount;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tag in tags)
                    _buildItem(
                      context: context,
                      size: itemWidth,
                      selected: selectedTags.contains(tag.id),
                      onTap: () => onToggle(tag),
                      child: Text(tag.emoji ?? '', style: const TextStyle(fontSize: 22.0)),
                    ),
                  _buildItem(
                    context: context,
                    size: itemWidth,
                    selected: false,
                    onTap: onAdd,
                    child: Icon(
                      SpIcons.add,
                      size: itemWidth * 0.45,
                      color: ColorScheme.of(context).onSurface.withValues(alpha: 0.4),
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

  Widget _buildItem({
    required BuildContext context,
    required double size,
    required bool selected,
    required void Function() onTap,
    required Widget child,
  }) {
    return SpTapEffect(
      scaleActive: 1.3,
      effects: [.scaleDown],
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: .center,
        decoration: BoxDecoration(
          shape: .circle,
          color: selected ? ColorScheme.of(context).surface.withValues(alpha: 0.5) : Colors.transparent,
          border: Border.all(
            color: selected
                ? ColorScheme.of(context).onSurface
                : Theme.of(context).disabledColor.withValues(alpha: 0.1),
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: child,
      ),
    );
  }
}
