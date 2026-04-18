import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

/// A single date cell in the calendar.
///
/// Displays a date with optional feeling indicator and handles selection state.
class SpCalendarDateCell extends StatelessWidget {
  const SpCalendarDateCell({
    super.key,
    required this.feelingVisibleIndexNotifier,
    required this.date,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.feelings,
    required this.isDisplayMonth,
    required this.onTap,
  });

  final ValueNotifier<int> feelingVisibleIndexNotifier;
  final DateTime date;
  final int selectedYear;
  final int selectedMonth;
  final int? selectedDay;
  final List<String>? feelings;
  final bool isDisplayMonth;
  final VoidCallback? onTap;

  bool get hasFeelings =>
      isDisplayMonth && feelings != null && feelings!.any((feeling) => feeling != 'exist_but_not_set');

  bool get hasStoriesButNoFeelings =>
      isDisplayMonth && feelings != null && feelings!.every((feeling) => feeling == 'exist_but_not_set');

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: [.scaleDown, .touchableOpacity],
      scaleActive: 0.9,
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
    Color? backgroundColor = isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null;
    Color foregroundColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    if (!isDisplayMonth) {
      foregroundColor = foregroundColor.withValues(alpha: 0.5);
    }

    if (hasFeelings) {
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
        padding: const EdgeInsets.all(4.0),
        child: FittedBox(
          child: buildFeelings(
            feelings: feelings!.where((feeling) => feeling != 'exist_but_not_set').toList(),
          ),
        ),
      );
    } else if (hasStoriesButNoFeelings) {
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

  Widget buildFeelings({
    required List<String> feelings,
  }) {
    if (feelings.length == 1) {
      return Text(
        feelings.first,
        strutStyle: const StrutStyle(
          fontSize: 56,
          height: 1.0,
        ),
        style: const TextStyle(
          fontSize: 56,
          height: 1.0,
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: feelingVisibleIndexNotifier,
      builder: (context, visibleIndex, child) {
        int index = visibleIndex % feelings.length;
        final emoji = feelings[index];

        return KeyedSubtree(
          key: ValueKey(emoji),
          child: SpFadeIn.flip(
            duration: const Duration(seconds: 1),
            child: Text(
              emoji,
              strutStyle: const StrutStyle(
                fontSize: 56,
                height: 1.0,
              ),
              style: const TextStyle(
                fontSize: 100,
                height: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
