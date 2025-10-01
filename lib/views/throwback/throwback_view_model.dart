import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'throwback_view.dart';

class ThrowbackViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ThrowbackRoute params;

  ThrowbackViewModel({
    required this.params,
  });

  late final int month = params.month;
  late final int day = params.day;

  int editedKey = 0;

  void refreshList() {
    editedKey++;
    notifyListeners();
  }

  // include every year (no need to exclude this year even it is throwback - past memory).
  // because user may write response to their past. We want them to appear here.
  late final filter = SearchFilterObject(
    month: month,
    day: day,
    years: {},
    types: {PathType.docs, PathType.archives},
    tagId: null,
    assetId: null,
  );

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(
      id: null,
      initialYear: DateTime.now().year,
      initialMonth: month,
      initialDay: day,
    ).push(context);

    editedKey += 1;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1)).then((_) {
      HomeView.reload(debugSource: '$runtimeType#goToNewPage');
    });
  }
}
