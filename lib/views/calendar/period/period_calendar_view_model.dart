import 'dart:async';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/calendar/period/period_calendar_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/widgets/calendar/sp_calendar.dart';

class PeriodCalendarViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final PeriodCalendarView params;

  PeriodCalendarViewModel({
    required this.params,
    required BuildContext context,
  }) {
    load();
    params.monthYearNotifier.addListener(_onParentMonthYearChanged);
  }

  final SpCalendarController calendarController = SpCalendarController();

  late int month = params.monthYearNotifier.value.month;
  late int year = params.monthYearNotifier.value.year;

  List<EventDbModel> _lastMonthPeriodEvents = [];
  List<EventDbModel> get lastMonthPeriodEvents => _lastMonthPeriodEvents;

  List<EventDbModel> _periodEvents = [];
  Set<DateTime> get periodDates => _periodEvents.map((e) => DateTime(e.year, e.month, e.day)).toSet();

  EventDbModel? _selectedEvent;
  EventDbModel? get selectedEvent => _selectedEvent;

  CollectionDbModel<StoryDbModel>? _selectedEventStories;
  CollectionDbModel<StoryDbModel> get selectedEventStories => _selectedEventStories ?? CollectionDbModel(items: []);

  DateTime? get selectedEventDate => _selectedEvent?.date;

  bool isPeriodDate(DateTime date) {
    return _periodEvents.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool isLastMonthPeriodDate(DateTime date) {
    DateTime thisDateLastMonth = DateTime(
      date.month - 1 > 0 ? date.year : date.year - 1,
      date.month - 1 > 0 ? date.month - 1 : 12,
      date.day,
    );

    return _lastMonthPeriodEvents.any(
      (d) => d.year == thisDateLastMonth.year && d.month == thisDateLastMonth.month && d.day == thisDateLastMonth.day,
    );
  }

  bool isDateSelected(DateTime date) {
    return selectedEvent != null &&
        selectedEvent!.year == date.year &&
        selectedEvent!.month == date.month &&
        selectedEvent!.day == date.day;
  }

  Future<void> load({
    DateTime? initialSelectedDate,
  }) async {
    _lastMonthPeriodEvents = await EventDbModel.db
        .where(
          filters: {
            "year": month - 1 > 0 ? year : year - 1,
            "month": month - 1 > 0 ? month - 1 : 12,
            "event_type": 'period',
          },
        )
        .then((e) => e?.items ?? []);

    _periodEvents = await EventDbModel.db
        .where(filters: {'year': year, 'month': month, 'event_type': 'period'})
        .then((e) => e?.items ?? []);

    _selectedEvent =
        _periodEvents
            .where(
              (e) =>
                  e.year == initialSelectedDate?.year &&
                  e.month == initialSelectedDate?.month &&
                  e.day == initialSelectedDate?.day,
            )
            .firstOrNull ??
        _periodEvents.firstOrNull;

    _selectedEventStories = selectedEvent?.id != null
        ? await StoryDbModel.db.where(
            filters: SearchFilterObject(
              years: {selectedEvent!.year},
              types: {PathType.docs},
              tagId: null,
              assetId: null,
              eventId: selectedEvent?.id,
            ).toDatabaseFilter(),
          )
        : null;

    notifyListeners();
  }

  // this will also trigger onMonthChanged from SpCalendar.
  void _onParentMonthYearChanged() {
    final newMonth = params.monthYearNotifier.value.month;
    final newYear = params.monthYearNotifier.value.year;
    if (newMonth != month || newYear != year) {
      calendarController.goToMonth(newYear, newMonth);
    }
  }

  Future<void> toggleDate(BuildContext context, DateTime date) async {
    if (isDateSelected(date)) {
      await _removeEvent(context, date);
    } else {
      if (isPeriodDate(date)) {
        await load(initialSelectedDate: date);
      } else {
        await EventDbModel.period(date: date).createIfNotExist();
        await load(initialSelectedDate: date);
      }
    }
  }

  Future<void> _removeEvent(BuildContext context, DateTime date) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr('dialog.are_you_sure_to_delete_period_date.title'),
      isDestructiveAction: true,
      message: selectedEventStories.items.isNotEmpty == true
          ? tr('dialog.are_you_sure_to_delete_period_date.message')
          : null,
      okLabel: tr('button.delete'),
      cancelLabel: tr('button.cancel'),
    );

    if (result == OkCancelResult.ok) {
      await EventDbModel.db.delete(_selectedEvent!.id);
      await StoryDbModel.db.where(filters: {'event_id': _selectedEvent!.id}).then((stories) async {
        for (StoryDbModel story in stories?.items ?? []) {
          await story.delete();
        }
      });

      await load(initialSelectedDate: date);
    }
  }

  void onMonthChanged(int year, int month) async {
    this.year = year;
    this.month = month;

    await load();

    if (params.monthYearNotifier.value.month != month || params.monthYearNotifier.value.year != year) {
      params.monthYearNotifier.value = (year: year, month: month);
    }
  }

  void goToNewPage(BuildContext context) async {
    if (selectedEvent == null) return;

    DateTime date = DateTime(selectedEvent!.year, selectedEvent!.month, selectedEvent!.day);
    final addedStory = await EditStoryRoute(
      id: null,
      initialYear: year,
      initialMonth: month,
      initialDay: selectedEvent?.day,
      initialEventId: selectedEvent!.id,
    ).push(context);

    if (addedStory is StoryDbModel) {
      if (addedStory.month != month || addedStory.year != year) {
        calendarController.goToMonth(addedStory.year, addedStory.month);
      }
      date = DateTime(addedStory.year, addedStory.month, addedStory.day);
    }

    await load(initialSelectedDate: date);
    Future.delayed(const Duration(seconds: 1)).then((_) {
      HomeView.reload(debugSource: '$runtimeType#goToNewPage');
    });
  }

  @override
  void dispose() {
    params.monthYearNotifier.removeListener(_onParentMonthYearChanged);
    super.dispose();
  }
}
