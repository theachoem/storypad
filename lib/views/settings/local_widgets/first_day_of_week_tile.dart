import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_first_day_of_week_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class FirstDayOfWeekTile extends StatelessWidget {
  const FirstDayOfWeekTile({
    super.key,
    required this.weekday,
    required this.currentFirstDayOfWeek,
    required this.onChanged,
  });

  final int weekday;
  final FirstDayOfWeekOption currentFirstDayOfWeek;
  final void Function(FirstDayOfWeekOption value) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return FirstDayOfWeekTile(
          weekday: weekday,
          currentFirstDayOfWeek: provider.preferences.firstDayOfWeek,
          onChanged: (value) => provider.setFirstDayOfWeek(value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.calendar),
      title: Text(tr('list_tile.first_day_of_week.title')),
      subtitle: Text(_label(context, currentFirstDayOfWeek)),
      onTap: () {
        SpFirstDayOfWeekSheet(
          firstDayOfWeek: currentFirstDayOfWeek,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }

  String _label(BuildContext context, FirstDayOfWeekOption value) {
    final localeName = context.locale.toLanguageTag();

    switch (value) {
      case FirstDayOfWeekOption.monday:
        return DateFormat.EEEE(localeName).format(DateTime(2024, 1, 1));
      case FirstDayOfWeekOption.sunday:
        return DateFormat.EEEE(localeName).format(DateTime(2024, 1, 7));
    }
  }
}
