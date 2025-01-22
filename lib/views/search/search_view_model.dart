import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/concerns/schedule_concern.dart';
import 'search_view.dart';

class SearchViewModel extends BaseViewModel with ScheduleConcern {
  final SearchRoute params;

  SearchViewModel({
    required this.params,
  });

  ValueNotifier<String> queryNotifier = ValueNotifier('');

  void search(String query) {
    scheduleAction(() {
      queryNotifier.value = query;
    });
  }

  @override
  void dispose() {
    queryNotifier.dispose();
    super.dispose();
  }
}
