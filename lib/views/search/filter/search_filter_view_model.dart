import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'search_filter_view.dart';

class SearchFilterViewModel extends BaseViewModel {
  final SearchFilterRoute params;

  late SearchFilterObject searchFilter;

  SearchFilterViewModel({
    required this.params,
  }) {
    searchFilter = params.initialTune ?? SearchFilterObject.initial();
    load();
  }

  Map<int, int>? years;
  Map<PathType, int>? types;
  List<TagDbModel>? tags;

  Future<void> load() async {
    years = await StoryDbModel.db.getStoryCountsByYear();
    types = await StoryDbModel.db.getStoryCountsByType();
    tags = await TagDbModel.db.where().then((e) => e?.items);

    for (TagDbModel tag in tags ?? []) {
      tag.storiesCount = await StoryDbModel.db.count(filters: {'tag': tag.id});
    }

    notifyListeners();
  }

  void search(BuildContext context) {
    Navigator.maybePop(context, searchFilter);
  }

  void reset(BuildContext context) {
    searchFilter = SearchFilterObject.initial();
    notifyListeners();
  }
}
