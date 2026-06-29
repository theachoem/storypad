import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/stats/stats_range.dart';
import 'package:storypad/core/objects/stats/story_stats_object.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_toggle_list_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'stats_section.dart';
import 'stats_view_model.dart';

part 'stats_content.dart';
part 'local_widgets/stats_emoji_grid.dart';
part 'local_widgets/stats_label_list.dart';
part 'local_widgets/stats_metric_chip.dart';
part 'local_widgets/stats_trend.dart';
part 'local_widgets/stats_share_footer.dart';

class StatsRoute extends BaseRoute {
  StatsRoute({
    required this.initialRange,
  });

  @override
  String get routeName => "stats";

  factory StatsRoute.month(DateTime anchor) => StatsRoute(initialRange: StatsRange.month(anchor));

  final StatsRange initialRange;

  @override
  Widget buildPage(BuildContext context) => StatsView(params: this);
}

class StatsView extends StatelessWidget {
  const StatsView({super.key, required this.params});

  final StatsRoute params;

  int get _initialTabIndex {
    final range = params.initialRange;
    return range.type == StatsRangeType.month ? range.anchor.month : 0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 13,
      initialIndex: _initialTabIndex,
      child: Builder(
        builder: (context) => ChangeNotifierProvider<StatsViewModel>(
          create: (_) => StatsViewModel(
            initialRange: params.initialRange,
            tabController: DefaultTabController.of(context),
            devicePreferencesProvider: context.read<DevicePreferencesProvider>(),
          ),
          builder: (context, _) => _StatsContent(Provider.of(context)),
        ),
      ),
    );
  }
}
