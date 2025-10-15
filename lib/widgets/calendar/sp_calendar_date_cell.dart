import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

/// A single date cell in the calendar.
///
/// Displays a date with optional feeling indicator and handles selection state.
class SpCalendarDateCell extends StatelessWidget {
  const SpCalendarDateCell({
    super.key,
    required this.date,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.feeling,
    required this.isDisplayMonth,
    required this.onTap,
  });

  final DateTime date;
  final int selectedYear;
  final int selectedMonth;
  final int? selectedDay;
  final String? feeling;
  final bool isDisplayMonth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: [SpTapEffectType.scaleDown],
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isToday)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            ),
          Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 56),
            child: _buildDateContent(context),
          ),
        ],
      ),
    );
  }

  bool get isSelected {
    return "${date.day}-${date.month}-${date.year}" == "$selectedDay-$selectedMonth-$selectedYear";
  }

  bool get isToday {
    final now = DateTime.now();
    return date == DateTime(now.year, now.month, now.day);
  }

  Widget _buildDateContent(BuildContext context) {
    final hasFeeling = isDisplayMonth && feeling != null && FeelingObject.feelingsByKey[feeling] != null;
    final hasStoriesButNoFeeling = isDisplayMonth && feeling != null && FeelingObject.feelingsByKey[feeling] == null;

    final backgroundColor = isSelected ? Theme.of(context).colorScheme.primary : null;
    var foregroundColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    if (!isDisplayMonth) {
      foregroundColor = foregroundColor.withValues(alpha: 0.5);
    }

    if (hasFeeling) {
      return AnimatedContainer(
        key: const ValueKey('has-stories-has-feeling'),
        duration: Durations.medium1,
        curve: Curves.ease,
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        alignment: Alignment.center,
        child: FeelingObject.feelingsByKey[feeling]?.image64.image(width: 26),
      );
    } else if (hasStoriesButNoFeeling) {
      return AnimatedContainer(
        key: const ValueKey('has-stories-no-feeling'),
        duration: Durations.medium1,
        curve: Curves.ease,
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        alignment: Alignment.center,
        child: Icon(SpIcons.check, color: foregroundColor),
      );
    } else {
      return AnimatedContainer(
        key: const ValueKey('no-stories'),
        duration: Durations.medium1,
        curve: Curves.ease,
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            DateFormatHelper.d(date, context.locale),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foregroundColor,
            ),
          ),
        ),
      );
    }
  }
}
