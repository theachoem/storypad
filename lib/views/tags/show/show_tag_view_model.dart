import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/views/search/search_view.dart';
import 'show_tag_view.dart';

class ShowTagViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowTagRoute params;

  ShowTagViewModel({
    required this.params,
  }) {
    _tag = params.tag;
    load();
  }

  late TagDbModel _tag;
  TagDbModel get tag => _tag;

  int editedKey = 0;
  List<int>? years;

  late final initialTune = SearchFilterObject(years: {}, types: {}, tagIds: {tag.id}, assetId: null);

  Future<void> load() async {
    years = await StoryDbModel.db
        .getStoryCountsByYear(filters: filter.toDatabaseFilter())
        .then((map) => map.keys.toList()..sort((a, b) => b.compareTo(a)));

    notifyListeners();
  }

  void refreshList() {
    editedKey++;
    load();
  }

  late SearchFilterObject filter = SearchFilterObject(
    years: {},
    types: {PathType.docs},
    tagIds: {tag.id},
    assetId: null,
  );

  Future<void> goToEditPage(BuildContext context) async {
    await context.read<TagsProvider>().editTag(context, tag);
    var editedTag = await TagDbModel.db.find(tag.id);

    // tags can be removed which mean we should pop show tag page.
    if (editedTag == null) {
      if (context.mounted) Navigator.pop(context);
    } else {
      _tag = editedTag;
    }

    await load();
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(
      id: null,
      initialTagIds: [tag.id],
    ).push(context);

    refreshList();

    Future.delayed(const Duration(seconds: 1)).then((_) {
      HomeView.reload(debugSource: '$runtimeType#goToNewPage');
    });
  }

  Future<void> goToSearchPage(BuildContext context) async {
    await SearchRoute(
      initialFilter: initialTune,
    ).push(context);
    refreshList();
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (SpStoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
      OkCancelResult result = await showOkCancelAlertDialog(
        context: context,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        isDestructiveAction: true,
        okLabel: tr("button.discard"),
      );
      shouldPop = result == OkCancelResult.ok;
    }

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }
}
