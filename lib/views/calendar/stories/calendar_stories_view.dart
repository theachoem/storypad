import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/calendar/sp_calendar.dart';
import 'package:storypad/widgets/calendar/sp_calendar_date_cell.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_scrollable_choice_chips.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'calendar_stories_view_model.dart';

part 'calendar_stories_content.dart';

class CalendarStoriesView extends StatelessWidget {
  const CalendarStoriesView({
    super.key,
    required this.monthNotifier,
    required this.yearNotifier,
  });

  final ValueNotifier<int> monthNotifier;
  final ValueNotifier<int> yearNotifier;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<CalendarStoriesViewModel>(
      create: (context) => CalendarStoriesViewModel(
        params: this,
        context: context,
      ),
      builder: (context, viewModel, child) {
        return _CalendarStoriesContent(viewModel);
      },
    );
  }
}
