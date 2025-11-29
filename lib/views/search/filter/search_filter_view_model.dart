import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:storypad/core/storages/search_filter_storage.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'search_filter_view.dart';

class SearchFilterViewModel extends ChangeNotifier with DisposeAwareMixin {
  final SearchFilterRoute params;

  late SearchFilterObject searchFilter;

  SearchFilterViewModel({
    required this.params,
  }) {
    searchFilter = params.initialTune;
    load();
  }

  Map<int, int>? years;
  List<TagDbModel>? tags;

  bool get filtered => jsonEncode(searchFilter.toDatabaseFilter()) != jsonEncode(params.resetTune.toDatabaseFilter());

  Future<void> load() async {
    if (params.filterTagModifiable) {
      years = await StoryDbModel.db.getStoryCountsByYear(
        filters: {
          if (searchFilter.types.isNotEmpty) 'types': searchFilter.types.map((e) => e.name).toList(),
        },
      );

      tags = await TagDbModel.db.where().then((e) => e?.items);
      await _resetTagsCount();
    } else {
      years = await StoryDbModel.db.getStoryCountsByYear(
        filters: {
          'tag': searchFilter.tagId,
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

  void toggleTag(TagDbModel tag) {
    searchFilter = searchFilter.copyWith(tagId: tag.id == searchFilter.tagId ? null : tag.id);
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
    var result = StoryDbModel.db.getStoryCountByTags(
      tagIds: tags?.map((e) => e.id).toList() ?? [],
      years: searchFilter.years.toList(),
      types: searchFilter.types.isNotEmpty ? searchFilter.types.map((e) => e.name).toList() : null,
    );

    for (TagDbModel tag in tags ?? []) {
      tag.storiesCount = result[tag.id];
    }
  }
}
