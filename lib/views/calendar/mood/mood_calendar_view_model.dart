import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/widgets/calendar/sp_calendar.dart';
import 'mood_calendar_view.dart';

class MoodCalendarViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final MoodCalendarView params;

  MoodCalendarViewModel({
    required this.params,
    required BuildContext context,
  }) {
    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);

    _tags = [...context.read<TagsProvider>().tags?.items ?? []];
    if (_tags?.isNotEmpty == true) _tags?.insert(0, TagDbModel.fromIDTitle(0, tr('general.all')));

    currentFilterStoriesCount = StoryDbModel.db.getStoryCountBy(filters: searchFilter.toDatabaseFilter());

    StoryDbModel.db.addGlobalListener(_reloadFeeling);
    params.monthYearNotifier.addListener(_onParentMonthYearChanged);
  }

  final SpCalendarController calendarController = SpCalendarController();

  List<TagDbModel>? _tags;
  List<TagDbModel>? get tags => _tags;

  late int month = params.monthYearNotifier.value.month;
  late int year = params.monthYearNotifier.value.year;

  int? selectedDay;
  int? selectedTagId;
  int? currentFilterStoriesCount;

  Map<int, String?> feelingMapByDay = {};

  bool tagSelected(TagDbModel tag) => (selectedTagId == tag.id) || (tag.id == 0 && selectedTagId == null);
  SearchFilterObject get searchFilter {
    return SearchFilterObject(
      years: {year},
      month: month,
      day: selectedDay,
      types: {PathType.docs},
      tagId: selectedTagId,
      assetId: null,
    );
  }

  // only reload feeling when listen to DB.
  // story query list already know how to refresh their own list, so we don't have to refresh for them.
  Future<void> _reloadFeeling() async {
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
      // Navigate to the story's month if different
      if (addedStory.month != month || addedStory.year != year) {
        calendarController.goToMonth(addedStory.year, addedStory.month);
      }
      selectedDay = addedStory.day;
    }

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
  ) async {
    if (year != this.year || month != this.month || selectedTagId != this.selectedTagId) {
      feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(
        month: month,
        year: year,
        tagId: selectedTagId,
      );
    }

    this.selectedDay = year != this.year || month != this.month ? null : selectedDay;
    this.year = year;
    this.month = month;
    this.selectedTagId = selectedTagId;

    currentFilterStoriesCount = StoryDbModel.db.getStoryCountBy(
      filters: searchFilter.toDatabaseFilter(),
    );

    notifyListeners();
  }

  void selectTag(TagDbModel tag) {
    onChanged(year, month, selectedDay, tag.id == 0 ? null : tag.id);
  }

  void onMonthChanged(int year, int month) {
    onChanged(year, month, selectedDay, selectedTagId);

    if (params.monthYearNotifier.value.month != month || params.monthYearNotifier.value.year != year) {
      params.monthYearNotifier.value = (year: year, month: month);
    }
  }

  // this will also trigger onMonthChanged from SpCalendar.
  void _onParentMonthYearChanged() {
    final newMonth = params.monthYearNotifier.value.month;
    final newYear = params.monthYearNotifier.value.year;
    if (newMonth != month || newYear != year) {
      calendarController.goToMonth(newYear, newMonth);
    }
  }

  void onDaySelected(int year, int month, int? day) {
    onChanged(year, month, day, selectedTagId);
  }

  void navigateToMonth(int year, int month) {
    calendarController.goToMonth(year, month);
  }

  @override
  void dispose() {
    params.monthYearNotifier.removeListener(_onParentMonthYearChanged);
    StoryDbModel.db.removeGlobalListener(_reloadFeeling);
    super.dispose();
  }
}
