import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';

import 'period_cycle_calendar_view_model.dart';

part 'period_cycle_calendar_content.dart';

class PeriodCycleCalendarView extends StatelessWidget {
  const PeriodCycleCalendarView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<PeriodCycleCalendarViewModel>(
      create: (context) => PeriodCycleCalendarViewModel(params: this),
      builder: (context, viewModel, child) {
        return _PeriodCycleCalendarContent(viewModel);
      },
    );
  }
}
