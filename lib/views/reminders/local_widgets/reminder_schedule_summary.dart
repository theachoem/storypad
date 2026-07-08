import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// e.g. "Every day at 9:00 PM" or "Mon, Wed at 9:00 PM". Shared by the
/// reminders list (tile subtitle) and the custom reminder edit page (live
/// preview), so both read from the same wording as the user edits.
String reminderScheduleSummary(BuildContext context, {required TimeOfDay time, required Set<int> weekdays}) {
  final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(time);

  if (weekdays.isEmpty) {
    return tr('reminder.summary.every_day', namedArgs: {'S_TIME': formattedTime});
  }

  final ordered = weekdays.toSet().toList()..sort();
  final labels = ordered.map((w) => DateFormat.E(context.locale.toString()).format(DateTime(2024, 1, w)));
  return tr(
    'reminder.summary.selected_days',
    namedArgs: {
      'S_DAYS': labels.join(', '),
      'S_TIME': formattedTime,
    },
  );
}
