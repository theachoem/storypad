import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

class SpCalendarPeriodDateCell extends StatelessWidget {
  const SpCalendarPeriodDateCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isPeriodDate,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isPeriodDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPeriodDate ? colorScheme.error.withValues(alpha: 0.1) : null,
          shape: BoxShape.circle,
          border: isPeriodDate ? Border.all(color: colorScheme.error.withValues(alpha: 0.3)) : null,
        ),
        child: Center(
          child: Text(
            DateFormatHelper.d(date, context.locale),
            style: TextStyle(
              fontWeight: isPeriodDate ? FontWeight.bold : FontWeight.normal,
              color: isCurrentMonth ? (isPeriodDate ? colorScheme.error : null) : theme.disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
