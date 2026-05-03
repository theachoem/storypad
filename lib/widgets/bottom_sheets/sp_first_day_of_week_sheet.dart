import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpFirstDayOfWeekSheet extends BaseBottomSheet {
  const SpFirstDayOfWeekSheet({
    required this.firstDayOfWeek,
    required this.onChanged,
  });

  final FirstDayOfWeekOption firstDayOfWeek;
  final void Function(FirstDayOfWeekOption value) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: firstDayOfWeek,
      builder: (context, selectedValue, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...FirstDayOfWeekOption.values.map((option) {
                return ListTile(
                  title: Text(_label(context, option)),
                  trailing: Visibility(
                    visible: option == selectedValue,
                    child: SpFadeIn.fromBottom(
                      child: Icon(
                        SpIcons.checkCircle,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    notifier.value = option;
                    onChanged(notifier.value);
                  },
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  String _label(BuildContext context, FirstDayOfWeekOption value) {
    final localeName = context.locale.toLanguageTag();
    final baseLabel = switch (value) {
      FirstDayOfWeekOption.monday => DateFormat.EEEE(localeName).format(DateTime(2024, 1, 1)),
      FirstDayOfWeekOption.sunday => DateFormat.EEEE(localeName).format(DateTime(2024, 1, 7)),
    };

    if (value == FirstDayOfWeekOption.defaultValue) {
      return '$baseLabel (${tr('general.default')})';
    }

    return baseLabel;
  }
}
