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
import 'calendar_view.dart';

class CalendarViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final CalendarRoute params;

  CalendarViewModel({
    required this.params,
    required BuildContext context,
  }) {
    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
    StoryDbModel.db.addGlobalListener(_reloadFeeling);

    load(context);
  }

  @override
  void dispose() {
    StoryDbModel.db.removeGlobalListener(_reloadFeeling);
    super.dispose();
  }

  final SpCalendarController calendarController = SpCalendarController();

  List<TagDbModel>? _tags;
  List<TagDbModel>? get tags => _tags;

  late int month = params.initialMonth ?? DateTime.now().month;
  late int year = params.initialYear ?? DateTime.now().year;

  int? selectedDay;
  int? selectedTagId;
  int? currentFilterStoriesCount;

  Map<int, String?> feelingMapByDay = {};
  int _editedKey = 0;
  int get editedKey => _editedKey;

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

  Future<void> load(BuildContext context) async {
    final tagProvider = context.read<TagsProvider>();
    await tagProvider.reload();

    _tags = tagProvider.tags?.items ?? [];
    _tags!.insert(0, TagDbModel.fromIDTitle(0, tr('general.all')));

    notifyListeners();
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

    _editedKey += 1;
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

    _editedKey += 1;
    notifyListeners();
  }

  void onMonthChanged(int year, int month) {
    onChanged(year, month, selectedDay, selectedTagId);
  }

  void onDaySelected(int year, int month, int? day) {
    onChanged(year, month, day, selectedTagId);
  }

  void navigateToMonth(int year, int month) {
    calendarController.goToMonth(year, month);
  }
}
