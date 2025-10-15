import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/calendar/sp_calendar.dart';
import 'package:storypad/widgets/calendar/sp_calendar_period_date_cell.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';
import 'period_calendar_view_model.dart';

part 'period_calendar_content.dart';

class PeriodCalendarView extends StatelessWidget {
  const PeriodCalendarView({
    super.key,
    required this.monthYearNotifier,
  });

  final ValueNotifier<({int year, int month})> monthYearNotifier;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<PeriodCalendarViewModel>(
      create: (context) => PeriodCalendarViewModel(params: this, context: context),
      builder: (context, viewModel, child) {
        return _PeriodCalendarContent(viewModel);
      },
    );
  }
}
