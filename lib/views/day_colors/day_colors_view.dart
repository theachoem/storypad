import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_adaptive_pop_up_button.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

part "local_widgets/day_color_tile.dart";

class DayColorsRoute extends BaseRoute {
  const DayColorsRoute();

  @override
  String? get routeName => 'day_colors';

  @override
  Widget buildPage(BuildContext context) => const DayColorsView();
}

class DayColorsView extends StatelessWidget {
  const DayColorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DevicePreferencesProvider>(context);
    final weekdays = _orderedWeekdays(provider.preferences.firstDayOfWeek);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("list_tile.day_colors.title")),
        actions: [
          SpPopupMenuButton(
            fromAppBar: true,
            items: (context) {
              final hasCustomizations = provider.preferences.colorByDay?.isNotEmpty ?? false;
              return [
                SpPopMenuItem(
                  leadingIconData: SpIcons.refresh,
                  title: tr("button.reset"),
                  // Grey out and disable when there is nothing to reset.
                  titleStyle: hasCustomizations ? null : TextStyle(color: Theme.of(context).disabledColor),
                  onPressed: hasCustomizations ? () => provider.resetAllDayColors() : null,
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                tooltip: tr("button.more_options"),
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final weekday in weekdays) _DayColorTile(weekday: weekday),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 120.0),
        ],
      ),
    );
  }

  // Order weekdays so the user's first day of week comes first.
  List<int> _orderedWeekdays(FirstDayOfWeekOption firstDayOfWeek) {
    const allDays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    final startIndex = allDays.indexOf(firstDayOfWeek.value);
    return [...allDays.sublist(startIndex), ...allDays.sublist(0, startIndex)];
  }
}
