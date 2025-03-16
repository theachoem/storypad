import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/story_list/story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'search_view.dart';

class SearchViewModel extends BaseViewModel with DebounchedCallback {
  final SearchRoute params;

  SearchViewModel({
    required this.params,
  });

  ValueNotifier<String> queryNotifier = ValueNotifier('');

  final SearchFilterObject initialFilter = SearchFilterObject(
    years: {},
    types: {PathType.docs},
    tagId: null,
    assetId: null,
  );

  late SearchFilterObject filter = initialFilter;

  void search(String query) {
    debouncedCallback(() {
      queryNotifier.value = query.trim();

      AnalyticsService.instance.logSearch(
        searchTerm: query.trim(),
      );
    });
  }

  @override
  void dispose() {
    queryNotifier.dispose();
    super.dispose();
  }

  Future<void> goToFilterPage(BuildContext context) async {
    final result = await SearchFilterRoute(
      initialTune: filter,
      multiSelectYear: true,
      filterTagModifiable: true,
      resetTune: initialFilter,
    ).push(context);

    if (result is SearchFilterObject) {
      filter = result;
      notifyListeners();
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (StoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
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
