import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'show_tag_view.dart';

class ShowTagViewModel extends ChangeNotifier with DisposeAwareMixin {
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
    types: {PathType.docs},
    tagId: tag.id,
    assetId: null,
  );

  Future<void> goToEditPage(BuildContext context) async {
    await context.read<TagsProvider>().editTag(context, tag);
    _tag = await TagDbModel.db.find(tag.id) ?? _tag;
    notifyListeners();
  }

  Future<void> goToFilterPage(BuildContext context) async {
    final result = await SearchFilterRoute(
      initialTune: filter,
      multiSelectYear: true,
      filterTagModifiable: false,
      resetTune: SearchFilterObject(years: {}, types: {}, tagId: tag.id, assetId: null),
    ).push(context);

    if (result is SearchFilterObject) {
      filter = result;
      notifyListeners();
    }
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
