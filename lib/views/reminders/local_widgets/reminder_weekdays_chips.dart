import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';

/// Weekday picker for reminders. An empty [weekdays] set is the canonical
/// "every day" value once saved, but while editing it's shown literally —
/// no chips checked — so the user can build up a selection from scratch
/// (uncheck everything, then check just Monday) instead of every uncheck
/// bouncing back to "all selected".
class ReminderWeekdaysChips extends StatelessWidget {
  const ReminderWeekdaysChips({super.key, required this.weekdays, required this.onChanged});

  /// 1=Mon..7=Sun. Empty = every day (once saved).
  final Set<int> weekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final ordered = _orderedWeekdays(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        children: [
          for (final w in ordered)
            FilterChip(
              label: Text(_label(context, w)),
              selected: weekdays.contains(w),
              onSelected: (selected) => _toggle(w, selected),
            ),
        ],
      ),
    );
  }

  void _toggle(int weekday, bool selected) {
    final updated = Set<int>.from(weekdays);
    if (selected) {
      updated.add(weekday);
    } else {
      updated.remove(weekday);
    }
    onChanged(updated);
  }

  String _label(BuildContext context, int weekday) {
    // date with weekday == w for w in 1..7 (Jan 1 2024 is a Monday).
    return DateFormat.E(context.locale.toString()).format(DateTime(2024, 1, weekday));
  }

  List<int> _orderedWeekdays(BuildContext context) {
    final firstDay = context.read<DevicePreferencesProvider>().preferences.firstDayOfWeek.value;
    return List.generate(7, (i) => ((firstDay - 1 + i) % 7) + 1);
  }
}
