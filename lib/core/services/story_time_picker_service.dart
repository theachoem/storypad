import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/sp_pin_to_home_button.dart';
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

    if (kIsCupertino) {
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
                SpPinToHomeButton(
                  pinned: story.preferredShowTime,
                  disabled: onToggleShowTime == null,
                  onPressed: () async {
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
          initialValue: TimeOfDay.fromDateTime(story.displayPathDate),
          builder: (context, notifier) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCupertinoNavigator(context, notifier),
                    CupertinoTimerPicker(
                      initialTimerDuration: Duration(
                        hours: story.displayPathDate.hour,
                        minutes: story.displayPathDate.minute,
                      ),
                      mode: CupertinoTimerPickerMode.hm,
                      onTimerDurationChanged: (duration) => notifier.value = _durationToTimeOfDay(duration),
                    ),
                    SpPinToHomeButton(
                      pinned: story.preferredShowTime,
                      disabled: onToggleShowTime == null,
                      onPressed: () async {
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
      },
    );
  }

  Widget _buildCupertinoNavigator(BuildContext context, CmValueNotifier<TimeOfDay?> notifier) {
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
