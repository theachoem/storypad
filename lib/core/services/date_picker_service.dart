import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class DatePickerService {
  final BuildContext context;
  final DateTime currentDate;

  DatePickerService({
    required this.context,
    required this.currentDate,
  });

  Future<DateTime?> show() async {
    DateTime? date;

    if (kIsCupertino) {
      date = await _showCupertinoDatePicker();
    } else {
      date = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 100 * 365)),
        currentDate: currentDate,
      );
    }

    if (date == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      currentDate.hour,
      currentDate.minute,
      currentDate.second,
    );
  }

  Future<DateTime?> _showCupertinoDatePicker() async {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return SpSingleStateWidget<DateTime?>(
          initialValue: currentDate,
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
                    _buildCupertinoNavigator(context, notifier),
                    SizedBox(
                      height: 216,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: currentDate,
                        onDateTimeChanged: (date) => notifier.value = date,
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

  Widget _buildCupertinoNavigator(BuildContext context, CmValueNotifier<DateTime?> notifier) {
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
