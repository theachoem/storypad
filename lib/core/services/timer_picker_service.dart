import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class TimePickerService {
  final BuildContext context;
  final Duration initialTimer;

  TimePickerService({
    required this.context,
    required this.initialTimer,
  });

  Future<Duration?> showPicker() async {
    Duration? newTimer;

    if (kIsCupertino) {
      newTimer = await _showCupertinoTimePicker(context);
    } else {
      newTimer = await _showMaterialTimePicker();
    }

    return newTimer;
  }

  Future<Duration?> _showMaterialTimePicker() async {
    return showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) {
        return SpSingleStateWidget<Duration?>(
          initialValue: initialTimer,
          builder: (context, notifier) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 216,
                  child: CupertinoTimerPicker(
                    selectionOverlayBuilder: (context, {required int columnCount, required int selectedIndex}) {
                      return Container(
                        margin: EdgeInsets.only(right: selectedIndex == columnCount - 1 ? 0.0 : 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      );
                    },
                    initialTimerDuration: initialTimer,
                    mode: CupertinoTimerPickerMode.hm,
                    onTimerDurationChanged: (duration) => notifier.value = duration,
                  ),
                ),
                FilledButton(
                  child: Text(tr("button.done")),
                  onPressed: () => Navigator.pop(context, notifier.value),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        );
      },
    );
  }

  Future<Duration?> _showCupertinoTimePicker(BuildContext context) {
    return showCupertinoModalPopup<Duration>(
      context: context,
      builder: (BuildContext context) {
        return SpSingleStateWidget<Duration?>(
          initialValue: initialTimer,
          builder: (context, notifier) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16.0,
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
              ),
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
                      initialTimerDuration: initialTimer,
                      mode: CupertinoTimerPickerMode.hm,
                      onTimerDurationChanged: (duration) => notifier.value = duration,
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

  Widget _buildCupertinoNavigator(BuildContext context, CmValueNotifier<Duration?> notifier) {
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
