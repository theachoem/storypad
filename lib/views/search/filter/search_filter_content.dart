part of 'search_filter_view.dart';

class _SearchFilterContent extends StatelessWidget {
  const _SearchFilterContent(this.viewModel);

  final SearchFilterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        title: Text(tr("page.search_filter.title")),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: buildBody(context),
      bottomNavigationBar: _BottomNav(viewModel: viewModel),
    );
  }

  Widget buildBody(BuildContext context) {
    final tagsByCategory = viewModel.tagsByCategory;

    final children = [
      if (viewModel.years?.isNotEmpty == true) ...[
        _Title(title: tr("general.years")),
        buildYears(context),
        const SizedBox(height: 12.0),
      ],
      if (viewModel.params.filterTagModifiable && tagsByCategory != null) ...[
        for (final entry in tagsByCategory.entries)
          if (entry.value.isNotEmpty) ...[
            _Title(title: entry.key?.title ?? tr("general.tags")),
            buildTagChips(context, entry.key, entry.value),
            const SizedBox(height: 12.0),
          ],
      ],
      const Divider(),
      CheckboxListTile.adaptive(
        tristate: true,
        value: viewModel.searchFilter.starred,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        secondary: const Icon(SpIcons.bookmark),
        title: Text(tr("button.bookmark")),
        onChanged: (value) => viewModel.setStarred(value),
      ),
    ];

    if (children.isEmpty) return const Center(child: CircularProgressIndicator.adaptive());

    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: EdgeInsets.only(top: 12.0, bottom: MediaQuery.of(context).padding.bottom),
      children: children,
    );
  }

  Widget buildYears(BuildContext context) {
    return SpScrollableChoiceChips<int>(
      wrapWidth: 800,
      choices: viewModel.years?.keys.toList() ?? [],
      storiesCount: (int year) => viewModel.years?[year],
      toLabel: (int year) => year.toString(),
      selected: (int year) => viewModel.searchFilter.years.contains(year),
      onToggle: (int year) => viewModel.toggleYear(year),
    );
  }

  Widget buildTagChips(BuildContext context, TagCategoryDbModel? category, List<TagDbModel> tags) {
    final bool isEmoji = category != null;

    return SpScrollableChoiceChips<TagDbModel>(
      wrapWidth: 800,
      choices: tags,
      storiesCount: (TagDbModel tag) => tag.storiesCount,
      toLabel: (TagDbModel tag) => isEmoji ? (tag.emoji ?? '') : tag.title,
      selected: (TagDbModel tag) => viewModel.tagSelected(tag),
      onToggle: (TagDbModel tag) => viewModel.toggleTag(tag),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ).add(EdgeInsets.only(left: MediaQuery.of(context).padding.left, right: MediaQuery.of(context).padding.right)),
      child: Text(
        title,
        style: TextTheme.of(context).titleSmall?.copyWith(color: ColorScheme.of(context).primary),
      ),
    );
  }
}
