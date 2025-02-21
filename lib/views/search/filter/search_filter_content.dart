part of 'search_filter_view.dart';

class _SearchFilterContent extends StatelessWidget {
  const _SearchFilterContent(this.viewModel);

  final SearchFilterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.search_filter.title")),
      ),
      body: buildBody(context),
      bottomNavigationBar: _BottomNav(viewModel: viewModel),
    );
  }

  Widget buildBody(BuildContext context) {
    final children = [
      if (viewModel.years?.isNotEmpty == true) ...[
        _Title(title: tr("general.years")),
        buildYears(context),
        SizedBox(height: 12.0),
      ],
      if (viewModel.searchFilter.filterTagModifiable && viewModel.tags?.isNotEmpty == true) ...[
        _Title(title: tr("general.tags")),
        buildTags(context),
        SizedBox(height: 12.0),
      ],
      Divider(),
      CheckboxListTile.adaptive(
        tristate: true,
        value: viewModel.searchFilter.starred,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(tr("button.star")),
        onChanged: (value) {
          viewModel.searchFilter.setStarred(value);
          viewModel.notifyListeners();
        },
      ),
    ];

    if (children.isEmpty) return const Center(child: CircularProgressIndicator.adaptive());

    return ListView(
      padding: EdgeInsets.only(top: 12.0, bottom: MediaQuery.of(context).padding.bottom),
      children: children,
    );
  }

  Widget buildYears(BuildContext context) {
    return _ScrollableChoiceChips<int>(
      wrapWidth: 800,
      choices: viewModel.years?.keys.toList() ?? [],
      storiesCount: (int year) => viewModel.years?[year] ?? 0,
      toLabel: (int year) => year.toString(),
      selected: (int year) => viewModel.searchFilter.years.contains(year),
      onToggle: (int year) {
        viewModel.searchFilter.toggleYear(year);
        viewModel.notifyListeners();
      },
    );
  }

  Widget buildTags(BuildContext context) {
    return _ScrollableChoiceChips<TagDbModel>(
      wrapWidth: 800,
      choices: viewModel.tags ?? [],
      storiesCount: (TagDbModel tag) => tag.storiesCount,
      toLabel: (TagDbModel tag) => tag.title,
      selected: (TagDbModel tag) => viewModel.searchFilter.tagId == tag.id,
      onToggle: (TagDbModel tag) {
        viewModel.searchFilter.toggleTag(tag);
        viewModel.notifyListeners();
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Text(
        title,
        style: TextTheme.of(context).titleSmall?.copyWith(color: ColorScheme.of(context).primary),
      ),
    );
  }
}
