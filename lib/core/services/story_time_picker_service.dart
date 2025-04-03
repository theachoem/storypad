import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class StoryTimePickerService {
  final BuildContext context;
  final StoryDbModel story;
  final Future<void> Function()? onToggleShowTime;

  StoryTimePickerService({
    required this.context,
    required this.story,
    required this.onToggleShowTime,
  });

  Future<TimeOfDay?> showPicker() async {
    TimeOfDay? newTime;

    if (AppTheme.isCupertino(context)) {
      newTime = await _showCupertinoTimePicker(context);
    } else {
      newTime = await _showMaterialTimePicker(newTime);
    }

    return newTime;
  }

  TimeOfDay _durationToTimeOfDay(Duration duration) {
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  Future<TimeOfDay?> _showMaterialTimePicker(TimeOfDay? newTime) async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(story.displayPathDate),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child!,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(backgroundColor: ColorScheme.of(context).surface),
                  icon: Icon(story.preferredShowTime ? SpIcons.of(context).pinSlash : SpIcons.of(context).pin,
                      color: ColorScheme.of(context).primary),
                  label: Text(story.preferredShowTime ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
                  onPressed: onToggleShowTime == null
                      ? null
                      : () async {
                          onToggleShowTime!();
                          if (context.mounted) Navigator.maybePop(context);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(BuildContext context) {
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return SpSingleStateWidget<TimeOfDay?>(
          initialValue: null,
          builder: (context, notifier) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildCupertinoNavigator(context, notifier),
                    CupertinoTimerPicker(
                      initialTimerDuration: Duration(
                        hours: story.displayPathDate.hour,
                        minutes: story.displayPathDate.minute,
                      ),
                      mode: CupertinoTimerPickerMode.hm,
                      onTimerDurationChanged: (duration) => notifier.value = _durationToTimeOfDay(duration),
                    ),
                    buildCupertinoPinButton(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildCupertinoPinButton(BuildContext context) {
    return CupertinoButton.tinted(
      sizeStyle: CupertinoButtonSize.medium,
      onPressed: onToggleShowTime == null
          ? null
          : () async {
              onToggleShowTime!();
              if (context.mounted) Navigator.maybePop(context);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          Icon(story.preferredShowTime ? SpIcons.of(context).pinSlash : SpIcons.of(context).pin),
          Text(
            story.preferredShowTime ? tr("button.unpin_from_home") : tr("button.pin_to_home"),
          ),
        ],
      ),
    );
  }

  Widget buildCupertinoNavigator(BuildContext context, CmValueNotifier<TimeOfDay?> notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(tr("button.cancel")),
        ),
        CupertinoButton(
          child: Text(tr("button.done")),
          onPressed: () => Navigator.pop(context, notifier.value),
        ),
      ],
    );
  }
}
