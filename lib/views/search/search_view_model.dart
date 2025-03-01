import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
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
  late SearchFilterObject filter = params.initialFilter;

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
    final result = await SearchFilterRoute(initialTune: filter).push(context);

    if (result is SearchFilterObject) {
      filter = result;
      notifyListeners();
    }
  }
}
