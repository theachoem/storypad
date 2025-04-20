import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/sp_scrollable_choice_chips.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class DiscoverSearchContent extends StatefulWidget {
  const DiscoverSearchContent({
    super.key,
  });

  @override
  State<DiscoverSearchContent> createState() => _DiscoverSearchContentState();
}

class _DiscoverSearchContentState extends State<DiscoverSearchContent> {
  Map<int, int>? years;
  List<TagDbModel>? tags;

  bool get loaded => years?.isNotEmpty == true;

  SearchFilterObject searchFilter = SearchFilterObject(
    years: {2025},
    types: {PathType.docs},
    tagId: null,
    assetId: null,
  );

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    years = await StoryDbModel.db.getStoryCountsByYear(
      filters: {
        if (searchFilter.types.isNotEmpty) 'types': searchFilter.types.map((e) => e.name).toList(),
      },
    );

    tags = await TagDbModel.db.where().then((e) => e?.items);
    await _resetTagsCount();

    setState(() {});
  }

  Future<void> toggleYear(int year) async {
    setState(() {
      searchFilter = searchFilter.copyWith(years: {year});
    });

    await _resetTagsCount();
    setState(() {});
  }

  void toggleTag(TagDbModel tag) {
    searchFilter = searchFilter.copyWith(tagId: tag.id == searchFilter.tagId ? null : tag.id);
    setState(() {});
  }

  Future<void> _resetTagsCount() async {
    for (TagDbModel tag in tags ?? []) {
      tag.storiesCount = await StoryDbModel.db.count(filters: {
        'tag': tag.id,
        'years': searchFilter.years.toList(),
        if (searchFilter.types.isNotEmpty) 'types': searchFilter.types.map((e) => e.name).toList(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        headerSliverBuilder: (context, _) {
          return [
            if (loaded)
              SliverToBoxAdapter(
                child: buildHeader(context),
              )
          ];
        },
        body: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (!loaded) return const Center(child: CircularProgressIndicator.adaptive());
    if (years?.values.every((e) => e == 0) == true) return const SizedBox.shrink();

    return SpStoryList.withQuery(
      filter: searchFilter,
      disableMultiEdit: true,
    );
  }

  Widget buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 4.0),
        if (years?.isNotEmpty == true) ...[
          SpSectionTitle(title: tr("general.years")),
          buildYears(context),
          const SizedBox(height: 12.0),
        ],
        if (tags?.isNotEmpty == true) ...[
          SpSectionTitle(title: tr("general.tags")),
          buildTags(context),
          const SizedBox(height: 12.0),
        ],
        const SizedBox(height: 4.0),
        const Divider(height: 1),
      ],
    );
  }

  Widget buildYears(BuildContext context) {
    return SpScrollableChoiceChips<int>(
      wrapWidth: 800,
      choices: years?.keys.toList() ?? [],
      storiesCount: (int year) => years?[year],
      toLabel: (int year) => year.toString(),
      selected: (int year) => searchFilter.years.contains(year),
      onToggle: (int year) => toggleYear(year),
    );
  }

  Widget buildTags(BuildContext context) {
    return SpScrollableChoiceChips<TagDbModel>(
      wrapWidth: 800,
      choices: tags ?? [],
      storiesCount: (TagDbModel tag) => tag.storiesCount,
      toLabel: (TagDbModel tag) => tag.title,
      selected: (TagDbModel tag) => searchFilter.tagId == tag.id,
      onToggle: (TagDbModel tag) => toggleTag(tag),
    );
  }
}
