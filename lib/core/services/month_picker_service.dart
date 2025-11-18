import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class MonthPickerResult {
  final int month;
  final int year;

  MonthPickerResult({
    required this.month,
    required this.year,
  });
}

class MonthPickerService {
  final BuildContext context;
  final int month;
  final int year;

  MonthPickerService({
    required this.context,
    required this.month,
    required this.year,
  });

  MonthPickerResult get initialMonth => MonthPickerResult(month: month, year: year);

  Future<MonthPickerResult?> showPicker() async {
    if (kIsCupertino) {
      return _showCupertinoTimePicker();
    } else {
      return _showMaterialTimePicker();
    }
  }

  Future<MonthPickerResult?> _showMaterialTimePicker() async {
    return showModalBottomSheet<MonthPickerResult>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) {
        return SpSingleStateWidget<MonthPickerResult?>(
          initialValue: initialMonth,
          builder: (context, notifier) {
            return Column(
              mainAxisSize: .min,
              children: [
                SizedBox(
                  height: 216,
                  child: CupertinoDatePicker(
                    initialDateTime: DateTime(year, month),
                    mode: CupertinoDatePickerMode.monthYear,
                    selectionOverlayBuilder: (context, {required int columnCount, required int selectedIndex}) {
                      return Container(
                        margin: EdgeInsets.only(right: selectedIndex == columnCount - 1 ? 0.0 : 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      );
                    },
                    onDateTimeChanged: (DateTime value) {
                      notifier.value = MonthPickerResult(
                        month: value.month,
                        year: value.year,
                      );
                    },
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

  Future<MonthPickerResult?> _showCupertinoTimePicker() {
    return showCupertinoModalPopup<MonthPickerResult>(
      context: context,
      builder: (BuildContext context) {
        return SpSingleStateWidget<MonthPickerResult?>(
          initialValue: initialMonth,
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
                    SizedBox(
                      height: 216,
                      child: CupertinoDatePicker(
                        initialDateTime: DateTime(year, month),
                        mode: CupertinoDatePickerMode.monthYear,
                        onDateTimeChanged: (DateTime value) {
                          notifier.value = MonthPickerResult(
                            month: value.month,
                            year: value.year,
                          );
                        },
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

  Widget _buildCupertinoNavigator(BuildContext context, CmValueNotifier<MonthPickerResult?> notifier) {
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
