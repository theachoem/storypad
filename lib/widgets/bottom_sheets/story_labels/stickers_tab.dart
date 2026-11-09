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

  // Taps apply in tap order: a sticker still being saved isn't overtaken by a later tap. A queued tap still
  // applies if the tab is switched meanwhile (the sheet holds the selection).
  Future<void> _queue = Future.value();

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

  // Saves the sticker if needed, then toggles it from the sheet's latest set (not awaited: the sheet
  // updates its set at once and saves the story after), so quick taps neither wait nor undo each other.
  void _enqueue(TagDbModel tag, TagCategoryDbModel category, {Future<void> Function()? save}) {
    _queue = _queue.then((_) async {
      if (save != null) {
        await save();
      } else if (!tag.exist()) {
        await tag.save();
      }

      // In its category's row before the toggle: a later tap in a single-select category must exclude it.
      final row = emojisByCategory?[category];
      if (row != null && !row.any((e) => e.id == tag.id)) {
        emojisByCategory![category] = [...row, tag];
        if (mounted) setState(() {});
      }

      unawaited(_toggle(tag, category));
      if (mounted) debouncedCallback(_load);
    });
  }

  void _onPickCustomEmoji(String emoji, TagCategoryDbModel picked) {
    // A suggested emoji belongs to its own system category, whichever "+" picked it: it shows, and is
    // single-selected, there. Any other emoji goes to the category it was picked for.
    final suggestedIn = TagCategoryDbModel.systemCategories
        .where((c) => c.suggestTags().any((t) => t.emoji == emoji))
        .firstOrNull;
    final category = suggestedIn ?? picked;

    // 1 emoji = 1 tag: deterministic ID guarantees no duplicates across categories.
    final tag = TagDbModel.emoji(emoji, categoryId: category.id);

    _enqueue(
      tag,
      category,
      save: () async {
        if (!tag.exist()) return tag.save();
        if (suggestedIn != null) return;

        // A custom emoji used before moves to the category it was just picked for.
        final existing = await TagDbModel.db.find(tag.id);
        if (existing != null && existing.categoryId != category.id) {
          await TagDbModel.db.set(existing.copyWith(categoryId: category.id));
        }
      },
    );
  }

  Future<void> _openCustomEmojiPicker(TagCategoryDbModel category) async {
    final preferredCategory = await PreferredEmojiTabStorage().getCategoryFor(category.id);
    if (!mounted) return;

    final emoji = await _CustomEmojiSheet(
      category: category,
      initialCategory: preferredCategory,
    ).show<String>(context: context);

    if (emoji != null) _onPickCustomEmoji(emoji, category);
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
        // The route's scroll controller, which the scrollbar uses: desktop doesn't attach it by default.
        primary: true,
        // The sheet's safe area (see SpStoryLabelsSheet): emojis scroll under it.
        padding: EdgeInsets.only(top: 8.0, bottom: 16.0 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 24.0,
          children: [
            for (final entry in emojisByCategory!.entries)
              _EmojiSection(
                category: entry.key,
                tags: entry.value,
                selectedTags: widget.selectedTags,
                onToggle: (tag) => _enqueue(tag, entry.key),
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
      spacing: 8.0,
      children: [
        _SideInset(
          minimum: 16.0,
          child: _buildTitle(context),
        ),
        _SideInset(
          minimum: 16.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // As many cells as fit at 44pt or more (6–7 per row on phones).
              const gap = 8.0;
              const minItemWidth = 44.0;
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
                      child: Text(tag.emoji ?? '', style: const TextStyle(fontSize: 24.0)),
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

  // A plain heading in the text color, sized for a full-height sheet (the small primary-colored
  // section title was made for the old floating picker).
  Widget _buildTitle(BuildContext context) {
    return Text(
      category.title,
      style: TextTheme.of(context).titleMedium?.copyWith(fontWeight: .w600),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required double size,
    required bool selected,
    required void Function() onTap,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: SpTapEffect(
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
      ),
    );
  }
}
