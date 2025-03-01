import 'package:flutter/material.dart';
import 'package:storypad/views/tags/edit/edit_tag_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'show_tag_view.dart';

class ShowTagViewModel extends BaseViewModel {
  final ShowTagRoute params;

  ShowTagViewModel({
    required this.params,
  }) {
    _tag = params.tag;
  }

  late TagDbModel _tag;
  TagDbModel get tag => _tag;

  late SearchFilterObject filter = SearchFilterObject(
    years: {},
    types: {},
    tagId: tag.id,
    filterTagModifiable: false,
    assetId: null,
  );

  Future<void> goToEditPage(BuildContext context) async {
    final allTags = await TagDbModel.db.where().then((e) => e?.items ?? <TagDbModel>[]);
    if (!context.mounted) return;

    await EditTagRoute(
      tag: tag,
      allTags: allTags,
    ).push(context);

    _tag = await TagDbModel.db.find(tag.id) ?? _tag;
    notifyListeners();
  }

  Future<void> goToFilterPage(BuildContext context) async {
    final result = await SearchFilterRoute(initialTune: filter).push(context);

    if (result is SearchFilterObject) {
      filter = result;
      notifyListeners();
    }
  }
}
