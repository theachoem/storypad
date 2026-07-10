import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/services/on_this_day_prediction_service.dart';
import 'package:storypad/core/services/period_prediction_service.dart';
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

  // Predicted base dates (date only, no time) for the two types whose
  // schedule isn't derivable from local state alone — fetched once on open
  // so the "next reminder" preview can combine them with the live-edited
  // time/daysAhead as the user adjusts those fields.
  DateTime? _predictedOnThisDayDate;
  DateTime? _predictedPeriodStart;
  bool _predictionLoaded = false;

  bool get _isPeriod => widget.reminder.type == ReminderType.period;
  bool get _isOnThisDay => widget.reminder.type == ReminderType.onThisDay;

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

    if (_isOnThisDay) {
      _loadOnThisDayPrediction();
    } else if (_isPeriod) {
      _loadPeriodPrediction();
    } else {
      _predictionLoaded = true;
    }
  }

  // Same horizon as LocalNotificationService._scheduleOnThisDay, so this
  // preview matches what actually gets scheduled.
  Future<void> _loadOnThisDayPrediction() async {
    final dates = await OnThisDayPredictionService.loadUpcomingMemoryDates(maxResults: 1);
    if (!mounted) return;
    setState(() {
      _predictedOnThisDayDate = dates.firstOrNull;
      _predictionLoaded = true;
    });
  }

  Future<void> _loadPeriodPrediction() async {
    final predicted = await PeriodPredictionService.loadPredictedNextPeriodStart();
    if (!mounted) return;
    setState(() {
      _predictedPeriodStart = predicted;
      _predictionLoaded = true;
    });
  }

  /// Next time this reminder would actually fire, given the in-progress edits
  /// — lets the user sanity-check the schedule before saving. `null` means no
  /// prediction is available yet (e.g. not enough period history, or no
  /// upcoming on-this-day memories in the schedule horizon).
  DateTime? get _nextOccurrence {
    if (_isPeriod) {
      final start = _predictedPeriodStart;
      if (start == null) return null;
      final target = start.subtract(Duration(days: _daysAhead));
      return DateTime(target.year, target.month, target.day, _time.hour, _time.minute);
    }

    if (_isOnThisDay) {
      final date = _predictedOnThisDayDate;
      if (date == null) return null;
      return DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
    }

    // Daily: mirrors LocalNotificationService._nextInstance, in local time.
    final now = DateTime.now();
    final normalized = ReminderObject.normalizeWeekdays(_weekdays);
    final slots = normalized.isEmpty ? const [0] : normalized;

    DateTime nextForSlot(int weekday) {
      var candidate = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
      if (weekday != 0) {
        while (candidate.weekday != weekday) {
          candidate = candidate.add(const Duration(days: 1));
        }
      }
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(Duration(days: weekday == 0 ? 1 : 7));
      }
      return candidate;
    }

    return slots.map(nextForSlot).reduce((a, b) => a.isBefore(b) ? a : b);
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ReminderWeekdaysChips(
                        weekdays: _weekdays,
                        onChanged: (updated) => setState(() => _weekdays = updated),
                      ),
                    ),
                  if (_isPeriod) _buildDaysAheadTile(context),
                  if (_enabled && _predictionLoaded) _buildScheduleHint(context),
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

  /// Below the fields: either "Your next reminder will be on ..." (when a
  /// future occurrence is known) or, for period reminders with too little
  /// logged history to predict from, a note telling the user what's missing.
  /// Shows nothing otherwise (e.g. a stale/past on-this-day prediction, or a
  /// period prediction that has enough history but nothing to say yet).
  Widget _buildScheduleHint(BuildContext context) {
    final nextOccurrence = _nextOccurrence;
    if (nextOccurrence != null && nextOccurrence.isAfter(DateTime.now())) {
      return _buildHint(
        context,
        tr(
          'reminder.next_occurrence.at',
          namedArgs: {'SP_DATE': DateFormatHelper.yMMMd(nextOccurrence, context.locale)},
        ),
      );
    }

    if (_isPeriod && _predictedPeriodStart == null) {
      return _buildHint(context, tr('reminder.period.needs_more_data'));
    }

    return const SizedBox.shrink();
  }

  Widget _buildHint(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SpIcons.info, size: 16, color: ColorScheme.of(context).onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorScheme.of(context).onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
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
            icon: const Icon(SpIcons.remove),
            onPressed: _daysAhead > 0 ? () => setState(() => _daysAhead--) : null,
          ),
          Text('$_daysAhead', style: Theme.of(context).textTheme.bodyMedium),
          IconButton(
            icon: const Icon(SpIcons.add),
            onPressed: _daysAhead < 31 ? () => setState(() => _daysAhead++) : null,
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
