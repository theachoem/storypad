import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_time_format_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class TimeFormatTile extends StatelessWidget {
  const TimeFormatTile({
    super.key,
    required this.weekday,
    required this.currentTimeFormat,
    required this.onChanged,
  });

  final int weekday;

  final TimeFormatOption currentTimeFormat;
  final void Function(TimeFormatOption value) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return TimeFormatTile(
          weekday: weekday,
          currentTimeFormat: provider.preferences.timeFormat,
          onChanged: (timeFormat) => provider.setTimeFormat(timeFormat),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.timer),
      title: Text(tr('general.time_format')),
      subtitle: Text(currentTimeFormat.label),
      onTap: () {
        SpTimeFormatSheet(
          timeFormat: currentTimeFormat,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }
}
