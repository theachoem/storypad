import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/services/calendar_days_generator.dart';
import 'package:storypad/core/services/month_picker_service.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'calendar_view_model.dart';

part 'calendar_content.dart';
part 'local_widgets/calendar_month.dart';
part 'local_widgets/calendar_date.dart';

class CalendarRoute extends BaseRoute {
  const CalendarRoute({
    required this.initialMonth,
    required this.initialYear,
  });

  final int? initialMonth;
  final int? initialYear;

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
      create: (context) => CalendarViewModel(params: params),
      builder: (context, viewModel, child) {
        return _CalendarContent(viewModel);
      },
    );
  }
}
