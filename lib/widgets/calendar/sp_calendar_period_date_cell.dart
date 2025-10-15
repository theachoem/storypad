import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpCalendarPeriodDateCell extends StatelessWidget {
  const SpCalendarPeriodDateCell({
    super.key,
    required this.date,
    required this.isDisplayMonth,
    required this.isPeriodDate,
    required this.onTap,
    required this.selected,
    required this.isLastMonthPeriodDate,
  });

  final DateTime date;
  final bool isDisplayMonth;
  final bool isPeriodDate;
  final bool isLastMonthPeriodDate;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dropColor = colorScheme.error;
    final lastMonthDropColor = colorScheme.readOnly.surface3;

    return Center(
      child: SpTapEffect(
        effects: [SpTapEffectType.scaleDown],
        scaleActive: 0.8,
        onTap: onTap != null
            ? () {
                Feedback.forTap(context);
                onTap!();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.all(6.0),
          alignment: Alignment.center,
          child: Stack(
            children: [
              if (isLastMonthPeriodDate)
                Icon(
                  SpIcons.waterDrop,
                  size: 44,
                  color: lastMonthDropColor,
                ),
              if (isPeriodDate)
                AnimatedContainer(
                  transformAlignment: Alignment.center,
                  curve: Curves.bounceOut,
                  duration: Durations.medium3,
                  transform: Matrix4.identity()..spScale(selected ? 1.2 : 1.0),
                  child: Icon(
                    SpIcons.waterDrop,
                    size: 44,
                    color: dropColor,
                  ),
                ),

              Center(
                child: Text(
                  DateFormatHelper.d(date, context.locale),
                  style: TextStyle(
                    fontWeight: isPeriodDate ? FontWeight.bold : FontWeight.normal,
                    color: isDisplayMonth ? (isPeriodDate ? colorScheme.onError : null) : theme.disabledColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
