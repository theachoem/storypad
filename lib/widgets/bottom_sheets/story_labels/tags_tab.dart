part of '../sp_story_labels_sheet.dart';

/// Tags (or people, with [peopleMode]): search, create, reorder, swipe to edit/delete.
class _TagsTab extends StatefulWidget {
  const _TagsTab({
    super.key,
    required this.peopleMode,
    required this.selectedTags,
    required this.storyCountByTagId,
    required this.onToggle,
  });

  final bool peopleMode;
  final Set<int> selectedTags;
  final Map<int, int> storyCountByTagId;
  final Future<void> Function(int id) onToggle;

  @override
  State<_TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends State<_TagsTab> {
  final _searchController = TextEditingController();

  String _query = '';
  bool _creating = false;
  bool get _peopleMode => widget.peopleMode;
  int? get _categoryId => _peopleMode ? TagCategoryDbModel.peopleId : null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggle(TagDbModel tag) => widget.onToggle(tag.id);

  Future<void> _create(TagsProvider provider) async {
    if (_creating) return;

    setState(() => _creating = true);
    final tag = await provider.createTag(_query, categoryId: _categoryId);

    if (tag != null && mounted) {
      await _toggle(tag);
      if (!mounted) return;
      setState(() {
        _query = '';
        _searchController.clear();
      });
    }

    if (mounted) setState(() => _creating = false);
  }

  List<TagDbModel> _filter(List<TagDbModel> tags) {
    if (_query.isEmpty) return tags;

    final fuzzy = Fuzzy<TagDbModel>(
      tags,
      options: FuzzyOptions(
        isCaseSensitive: false,
        keys: [WeightedKey(name: 'title', getter: (t) => t.title, weight: 1)],
      ),
    );

    final results = fuzzy.search(_query)..sort((a, b) => a.score.compareTo(b.score));
    return results.map((r) => r.item).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TagsProvider>(context);
    final tags = (_peopleMode ? provider.peopleTags : provider.tags)?.items ?? <TagDbModel>[];
    final allowCreate =
        _query.isNotEmpty && (tags.isEmpty || !tags.any((t) => t.title.toLowerCase() == _query.toLowerCase()));

    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 12.0),
        const Divider(height: 1),
        Expanded(
          child: !allowCreate && tags.isEmpty ? _buildEmpty() : _buildList(provider, _filter(tags), allowCreate),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return _SideInset(
      minimum: 16.0,
      child: TextField(
        autofocus: FocusManager.instance.primaryFocus?.hasFocus ?? false,
        controller: _searchController,
        onChanged: (text) => setState(() => _query = text),
        decoration: InputDecoration(
          isDense: true,
          hintText: _peopleMode ? tr('input.people.hint') : tr('input.tag.hint'),
          hintStyle: TextStyle(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorScheme.of(context).outline),
          ),
          suffixIconConstraints: const BoxConstraints(maxWidth: 32.0),
          suffixIcon: _query.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(SpIcons.add),
                )
              : null,
        ),
        style: TextTheme.of(context).bodyMedium,
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      keyboardDismissBehavior: .onDrag,
      padding: EdgeInsets.only(top: 48.0, bottom: 48.0 + MediaQuery.paddingOf(context).bottom),
      child: _SideInset(
        minimum: 24.0,
        child: Column(
          mainAxisSize: .min,
          spacing: 12.0,
          children: [
            Icon(_peopleMode ? SpIcons.people : SpIcons.tag, size: 24.0),
            Text(
              _peopleMode ? tr("page.tags.people_empty_message") : tr("page.tags.empty_message"),
              textAlign: .center,
              style: TextTheme.of(context).bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(TagsProvider provider, List<TagDbModel> tags, bool allowCreate) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: ReorderableListView(
        // Rows scroll under the sheet's safe area / keyboard (see SpStoryLabelsSheet); the tiles keep
        // clear of the side insets themselves, so the list and its scrollbar span the full width.
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        keyboardDismissBehavior: .onDrag,
        // Only the full list reorders: a filtered row's index isn't its place in the full list.
        buildDefaultDragHandles: _query.isEmpty,
        onReorderItem: (oldIndex, newIndex) {
          if (_query.isEmpty) provider.reorder(oldIndex, newIndex, categoryId: _categoryId);
        },
        children: [
          if (allowCreate) _buildCreateTile(provider),
          for (final tag in tags) _buildTagTile(provider, tag),
        ],
      ),
    );
  }

  Widget _buildCreateTile(TagsProvider provider) {
    return ListTile(
      key: const ValueKey('create'),
      onTap: () => _create(provider),
      leading: _creating
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator.adaptive())
          : const Icon(SpIcons.add),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${_peopleMode ? tr("page.new_person.title") : tr("page.new_tag.title")}: '),
            TextSpan(
              text: _query,
              style: const TextStyle(fontStyle: .italic, fontWeight: .bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagTile(TagsProvider provider, TagDbModel tag) {
    final desktop = <TargetPlatform>[.linux, .windows, .macOS].contains(Theme.of(context).platform);

    return Slidable(
      key: ValueKey(tag.id),
      closeOnScroll: true,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => provider.deleteTag(context, tag),
            backgroundColor: ColorScheme.of(context).error,
            foregroundColor: ColorScheme.of(context).onError,
            icon: SpIcons.delete,
            label: tr("button.delete"),
          ),
          SlidableAction(
            onPressed: (context) => provider.editTag(context, tag),
            backgroundColor: ColorScheme.of(context).secondary,
            foregroundColor: ColorScheme.of(context).onSecondary,
            icon: SpIcons.edit,
            label: tr("button.edit"),
          ),
        ],
      ),
      child: CheckboxListTile.adaptive(
        value: widget.selectedTags.contains(tag.id),
        onChanged: (_) => _toggle(tag),
        controlAffinity: .leading,
        contentPadding: const EdgeInsets.only(left: 8.0, right: 16.0),
        secondary: desktop || _query.isNotEmpty ? null : const Icon(SpIcons.dragIndicator),
        title: Text(tag.title),
        subtitle: Text(plural("plural.entry", widget.storyCountByTagId[tag.id] ?? 0)),
      ),
    );
  }
}
