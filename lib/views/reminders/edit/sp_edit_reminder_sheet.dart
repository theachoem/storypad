import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/types/reminder_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/reminders/local_widgets/reminder_weekdays_chips.dart';
import 'package:storypad/views/reminders/reminders_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// Edit sheet for **built-in** reminders (daily/on-this-day/period) only.
/// Custom reminders have more fields (message, template, tags) and live in
/// their own full page instead — see `edit_custom_reminder_view.dart`.
class SpEditReminderSheet extends BaseBottomSheet {
  const SpEditReminderSheet({required this.reminder});

  /// The built-in reminder being edited. For a not-yet-configured type, pass
  /// [ReminderObject.builtin].
  final ReminderObject reminder;

  // Compact sheet (like SpNicknameBottomSheet) — sized to content, not a full
  // page. Content ranges from "just a switch" to a handful of fields, so a
  // fullscreen sheet felt oversized, especially on iOS.
  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _SpEditReminderSheetBody(reminder: reminder, bottomPadding: bottomPadding);
  }
}

class _SpEditReminderSheetBody extends StatefulWidget {
  const _SpEditReminderSheetBody({required this.reminder, required this.bottomPadding});

  final ReminderObject reminder;

  /// Safe-area/keyboard-inset padding to reserve at the bottom, provided by
  /// the enclosing [BaseBottomSheet].
  final double bottomPadding;

  @override
  State<_SpEditReminderSheetBody> createState() => _SpEditReminderSheetBodyState();
}

class _SpEditReminderSheetBodyState extends State<_SpEditReminderSheetBody> {
  late bool _enabled;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late int _daysAhead;

  bool get _isPeriod => widget.reminder.type == ReminderType.period;

  /// Only daily reminders schedule per weekday — on-this-day/period fire on
  /// precomputed one-shot dates and ignore [ReminderObject.weekdays].
  bool get _supportsWeekdays => widget.reminder.type == ReminderType.daily;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _enabled = r.enabled;
    _time = r.timeOfDay;
    // Every day is stored as an empty set — show it as all 7 chips checked
    // so the user can see the current schedule before pruning it down.
    _weekdays = r.weekdays.isEmpty ? ReminderObject.allWeekdays.toSet() : r.weekdays.toSet();
    _daysAhead = r.daysAhead ?? 2;
  }

  Future<void> _setEnabled(bool value) async {
    if (value) {
      final granted = await ensureNotificationPermission(context);
      if (!granted) return;
    }
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _save() async {
    final updated = widget.reminder.copyWith(
      enabled: _enabled,
      hour: _time.hour,
      minute: _time.minute,
      weekdays: ReminderObject.normalizeWeekdays(_weekdays),
      daysAhead: _isPeriod ? _daysAhead : null,
    );

    await context.read<DevicePreferencesProvider>().upsertReminder(updated);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            value: _enabled,
            title: Text(widget.reminder.type.title),
            subtitle: Text(widget.reminder.type.description),
            onChanged: _setEnabled,
          ),
          // Always mounted (not hidden) so the sheet's content height stays
          // constant across the switch toggle — hiding/showing this block
          // caused the sheet to visibly jump/resize when turning it on.
          // Dimmed + non-interactive instead when off.
          IgnorePointer(
            ignoring: !_enabled,
            child: AnimatedOpacity(
              opacity: _enabled ? 1 : 0.4,
              duration: Durations.short4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(SpIcons.alarm),
                    title: Text(tr('reminder.field.time')),
                    trailing: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(_time),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: _pickTime,
                  ),
                  if (_supportsWeekdays)
                    ReminderWeekdaysChips(
                      weekdays: _weekdays,
                      onChanged: (updated) => setState(() => _weekdays = updated),
                    ),
                  if (_isPeriod) _buildDaysAheadTile(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(width: double.infinity, child: _buildSaveButton(context)),
          ),
          SizedBox(height: widget.bottomPadding + 16),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: _save,
        child: Text(tr('button.save')),
      );
    } else {
      return FilledButton(
        onPressed: _save,
        child: Text(tr('button.save')),
      );
    }
  }

  Widget _buildDaysAheadTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.calendar),
      title: Text(tr('reminder.field.days_ahead')),
      subtitle: Text(plural('plural.reminder_days_ahead', _daysAhead)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _daysAhead > 0 ? () => setState(() => _daysAhead--) : null,
          ),
          Text('$_daysAhead'),
          IconButton(
            icon: const Icon(SpIcons.add),
            onPressed: _daysAhead < 14 ? () => setState(() => _daysAhead++) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }
}
