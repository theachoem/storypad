import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
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

    if (AppTheme.isIOS(context)) {
      newTime = await _showCupertinoTimePicker(context);
    } else {
      newTime = await _showMaterialTimePicker(newTime);
    }

    return newTime;
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
                  icon: Icon(story.preferredShowTime ? MdiIcons.pinOff : MdiIcons.pin,
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
            TimeOfDay durationToTimeOfDay(Duration duration) {
              int hours = duration.inHours % 24;
              int minutes = duration.inMinutes % 60;
              return TimeOfDay(hour: hours, minute: minutes);
            }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          onPressed: () {},
                          child: Text(tr("button.cancel")),
                        ),
                        CupertinoButton(
                          child: Text(tr("button.done")),
                          onPressed: () => Navigator.pop(context, notifier.value),
                        ),
                      ],
                    ),
                    CupertinoTimerPicker(
                      initialTimerDuration: Duration(
                        hours: story.displayPathDate.hour,
                        minutes: story.displayPathDate.minute,
                      ),
                      mode: CupertinoTimerPickerMode.hm,
                      onTimerDurationChanged: (duration) {
                        notifier.value = durationToTimeOfDay(duration);
                      },
                    ),
                    CupertinoButton.tinted(
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
                          Icon(story.preferredShowTime ? CupertinoIcons.pin_slash : CupertinoIcons.pin),
                          Text(
                            story.preferredShowTime ? tr("button.unpin_from_home") : tr("button.pin_to_home"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
