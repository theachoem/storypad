import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/storages/search_filter_storage.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'search_filter_view.dart';

class SearchFilterViewModel extends ChangeNotifier with DisposeAwareMixin {
  final SearchFilterRoute params;
  late final TagsProvider tagsProvider;

  late SearchFilterObject searchFilter;

  SearchFilterViewModel({
    required this.params,
    required BuildContext context,
  }) {
    tagsProvider = context.read<TagsProvider>();
    searchFilter = params.initialTune;
    load();
  }

  Map<int, int>? years;

  // null key = non-emoji tags (no category); non-null key = emoji category
  Map<TagCategoryDbModel?, List<TagDbModel>>? tagsByCategory;

  bool get filtered => jsonEncode(searchFilter.toDatabaseFilter()) != jsonEncode(params.resetTune.toDatabaseFilter());

  Future<void> load() async {
    if (params.filterTagModifiable) {
      years = await StoryDbModel.db.getStoryCountsByYear(
        filters: {
          if (searchFilter.types.isNotEmpty) 'types': searchFilter.types.map((e) => e.name).toList(),
        },
      );

      final allItems = tagsProvider.allTags?.items ?? <TagDbModel>[];

      // category is nullable, null means it's a non-emoji tag without category.
      // Group those together with a null key.
      final Map<TagCategoryDbModel?, List<TagDbModel>> grouped = {
        null: allItems.where((tag) => tag.categoryId == null).toList(),
        for (final cateogy in TagCategoryDbModel.systemCategories)
          cateogy: allItems.where((tag) => tag.categoryId == cateogy.id).toList(),
      };

      tagsByCategory = grouped;
      await _resetTagsCount();

      tagsByCategory = {
        for (final entry in grouped.entries)
          entry.key: entry.value.where((tag) => tag.storiesCount != null && tag.storiesCount! > 0).toList()
            ..sort((a, b) => b.storiesCount!.compareTo(a.storiesCount!)),
      };
    } else {
      years = await StoryDbModel.db.getStoryCountsByYear(
        filters: {
          'tags': searchFilter.tagIds.toList(),
          if (searchFilter.types.isNotEmpty) 'types': searchFilter.types.map((e) => e.name).toList(),
        },
      );
    }

    notifyListeners();
  }

  void search(BuildContext context) {
    Navigator.maybePop(context, searchFilter);
  }

  void setStarred(bool? value) {
    searchFilter = searchFilter.copyWith(starred: value);
    notifyListeners();

    SearchFilterStorage().writeObject(searchFilter);
  }

  Future<void> toggleYear(int year) async {
    if (params.multiSelectYear) {
      var years = {...searchFilter.years};

      if (years.contains(year)) {
        years.remove(year);
      } else {
        years.add(year);
      }

      searchFilter = searchFilter.copyWith(years: years);
    } else {
      searchFilter = searchFilter.copyWith(years: {year});
    }

    notifyListeners();
    SearchFilterStorage().writeObject(searchFilter);

    await _resetTagsCount();
    notifyListeners();
  }

  bool tagSelected(TagDbModel tag) => searchFilter.tagIds.contains(tag.id);

  void toggleTag(TagDbModel tag) {
    // Single-select per category: remove any other selected tag in the same category first.
    final categoryTags =
        tagsByCategory?.entries
            .where((e) => e.key?.id == tag.categoryId)
            .expand((e) => e.value)
            .map((t) => t.id)
            .toSet() ??
        {};

    Set<int> newTagIds = {...searchFilter.tagIds}..removeAll(categoryTags);

    // Toggle: if tag was already selected it was removed above → do not re-add.
    if (!searchFilter.tagIds.contains(tag.id)) newTagIds.add(tag.id);
    searchFilter = searchFilter.copyWith(tagIds: newTagIds);
    notifyListeners();

    SearchFilterStorage().writeObject(searchFilter);
  }

  Future<void> reset(BuildContext context) async {
    searchFilter = params.resetTune;
    SearchFilterStorage().remove();
    await _resetTagsCount();
    notifyListeners();
  }

  Future<void> setSavingSearchFilter() async {
    SearchFilterStorage().writeObject(searchFilter);
    notifyListeners();
  }

  Future<void> _resetTagsCount() async {
    final allTags = tagsByCategory?.values.expand((list) => list).toList() ?? [];

    var result = StoryDbModel.db.getStoryCountByTags(
      tagIds: allTags.map((e) => e.id).toList(),
      years: searchFilter.years.toList(),
      types: searchFilter.types.isNotEmpty ? searchFilter.types.map((e) => e.name).toList() : null,
    );

    for (TagDbModel tag in allTags) {
      tag.storiesCount = result[tag.id];
    }
  }
}
