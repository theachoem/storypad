import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'package:storypad/core/services/month_picker_service.dart';
import 'package:storypad/views/calendar/period/period_calendar_view.dart';
import 'package:storypad/views/calendar/mood/mood_calendar_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'calendar_view_model.dart';

part 'calendar_content.dart';

class CalendarRoute extends BaseRoute {
  const CalendarRoute({
    required this.initialMonth,
    required this.initialYear,
    required this.initialSegment,
  });

  final int? initialMonth;
  final int? initialYear;
  final CalendarSegmentId? initialSegment;

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => CalendarView(params: this);
}

class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.params,
  });

  final CalendarRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<CalendarViewModel>(
      create: (context) => CalendarViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _CalendarContent(viewModel);
      },
    );
  }
}
