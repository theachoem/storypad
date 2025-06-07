import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'calendar_view.dart';

class CalendarViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CalendarRoute params;

  CalendarViewModel({
    required this.params,
  }) {
    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
    currentStoryCountByTabIndex[tabIndex] = StoryDbModel.db.getStoryCountBy(filters: filter.toDatabaseFilter());

    StoryDbModel.db.addGlobalListener(reloadFeeling);
  }

  late int month = params.initialMonth ?? DateTime.now().month;
  late int year = params.initialYear ?? DateTime.now().year;
  int? selectedDay;

  int? selectedTagId;
  Map<int, int> currentStoryCountByTabIndex = {};
  int tabIndex = 0;

  Map<int, String?> feelingMapByDay = {};
  int editedKey = 0;

  SearchFilterObject get filter {
    return SearchFilterObject(
      years: {year},
      month: month,
      day: selectedDay,
      types: {PathType.docs},
      tagId: selectedTagId,
      assetId: null,
    );
  }

  @override
  void dispose() {
    StoryDbModel.db.removeGlobalListener(reloadFeeling);
    super.dispose();
  }

  // only reload feeling when listen to DB.
  // story query list already know how to refresh their own list, so we don't have to refresh for them.
  Future<void> reloadFeeling() async {
    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
    notifyListeners();
  }

  Future<void> goToNewPage(BuildContext context) async {
    final addedStory = await EditStoryRoute(
      id: null,
      initialYear: year,
      initialMonth: month,
      initialDay: selectedDay,
      initialTagIds: selectedTagId != null ? [selectedTagId!] : null,
    ).push(context);

    if (addedStory is StoryDbModel) {
      month = addedStory.month;
      year = addedStory.year;
      selectedDay = addedStory.day;
    }

    editedKey += 1;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1)).then((_) {
      HomeView.reload(debugSource: '$runtimeType#goToNewPage');
    });
  }

  void onChanged(
    int year,
    int month,
    int? selectedDay,
    int? selectedTagId,
    int tabIndex,
  ) async {
    if (year != this.year || month != this.month || selectedTagId != this.selectedTagId) {
      feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(
        month: month,
        year: year,
        tagId: selectedTagId,
      );
    }

    this.tabIndex = tabIndex;
    this.selectedDay = year != this.year || month != this.month ? null : selectedDay;
    this.year = year;
    this.month = month;
    this.selectedTagId = selectedTagId;
    currentStoryCountByTabIndex[tabIndex] = StoryDbModel.db.getStoryCountBy(filters: filter.toDatabaseFilter());

    notifyListeners();
  }
}
