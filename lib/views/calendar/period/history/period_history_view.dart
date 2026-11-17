import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/period_cycle_object.dart';
import 'package:storypad/core/services/period_prediction_service.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_filled_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_metric_chip.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'period_history_view_model.dart';

part 'period_history_content.dart';

/// Past periods, newest first, with averages and the next predicted start.
/// Pops with the tapped cycle's start date so the calendar can jump to it.
class PeriodHistoryRoute extends BaseRoute {
  const PeriodHistoryRoute();

  @override
  Widget buildPage(BuildContext context) => PeriodHistoryView(params: this);
}

class PeriodHistoryView extends StatelessWidget {
  const PeriodHistoryView({
    super.key,
    required this.params,
  });

  final PeriodHistoryRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PeriodHistoryViewModel>(
      create: (context) => PeriodHistoryViewModel(params: params),
      builder: (context, child) => _PeriodHistoryContent(Provider.of(context)),
    );
  }
}
