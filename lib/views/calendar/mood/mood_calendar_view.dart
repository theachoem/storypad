import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/calendar/sp_calendar.dart';
import 'package:storypad/widgets/calendar/sp_calendar_date_cell.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_scrollable_choice_chips.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'mood_calendar_view_model.dart';

part 'mood_calendar_content.dart';

class MoodCalendarView extends StatelessWidget {
  const MoodCalendarView({
    super.key,
    required this.monthYearNotifier,
  });

  final ValueNotifier<({int year, int month})> monthYearNotifier;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<MoodCalendarViewModel>(
      create: (context) => MoodCalendarViewModel(
        params: this,
        context: context,
      ),
      builder: (context, viewModel, child) {
        return _CalendarStoriesContent(viewModel);
      },
    );
  }
}
