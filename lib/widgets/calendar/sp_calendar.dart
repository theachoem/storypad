import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/calendar_days_generator.dart';

part 'sp_calendar_month_grid.dart';

/// A reusable infinite scrollable calendar widget.
///
/// This widget provides a horizontally scrollable calendar that allows users
/// to navigate through months infinitely. It supports:
/// - Infinite horizontal scrolling through months
/// - Day selection
/// - Feeling/emotion indicators per day
/// - Custom styling for selected dates and today's date
/// - Custom cell builders for different calendar types
class SpCalendar extends StatefulWidget {
  const SpCalendar({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.cellBuilder,
    this.onMonthChanged,
    this.controller,
  });

  /// The initial year to display
  final int initialYear;

  /// The initial month to display (1-12)
  final int initialMonth;

  /// Callback when the visible month changes
  final void Function(int year, int month)? onMonthChanged;

  /// Optional controller to programmatically navigate the calendar
  final SpCalendarController? controller;

  /// Optional custom cell builder. If null, uses default feeling-based cell.
  final Widget Function(BuildContext context, DateTime date, bool isDisplayMonth) cellBuilder;

  @override
  State<SpCalendar> createState() => _SpCalendarState();
}

/// Controller for programmatically navigating the SpCalendar.
class SpCalendarController {
  _SpCalendarState? _state;

  void _attach(_SpCalendarState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Navigate to a specific month and year.
  void goToMonth(int year, int month) {
    _state?._navigateToMonth(year, month);
  }
}

class _SpCalendarState extends State<SpCalendar> {
  late PageController _pageController;
  late int _currentYear;
  late int _currentMonth;
  late int _baseYear;
  late int _baseMonth;

  // Using a large initial page to allow scrolling in both directions
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _baseYear = widget.initialYear;
    _baseMonth = widget.initialMonth;
    _currentYear = widget.initialYear;
    _currentMonth = widget.initialMonth;
    _pageController = PageController(initialPage: _initialPage);
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to a specific month programmatically
  void _navigateToMonth(int year, int month) {
    final targetPage = _calculatePageForMonth(year, month);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(targetPage);
    }
  }

  /// Calculate the page index for a specific year and month
  int _calculatePageForMonth(int year, int month) {
    final monthsDiff = (year - _baseYear) * 12 + (month - _baseMonth);
    return _initialPage + monthsDiff;
  }

  /// Calculates the year and month for a given page index
  ({int year, int month}) _getDateForPage(int pageIndex) {
    final offset = pageIndex - _initialPage;
    int year = _baseYear;
    int month = _baseMonth + offset;

    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }

    return (year: year, month: month);
  }

  void _onPageChanged(int pageIndex) {
    final date = _getDateForPage(pageIndex);

    if (date.year != _currentYear || date.month != _currentMonth) {
      setState(() {
        _currentYear = date.year;
        _currentMonth = date.month;
      });

      widget.onMonthChanged?.call(date.year, date.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8.0),
        _buildDaysHeader(context),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: _calculateCalendarHeight(constraints),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, pageIndex) {
                  final date = _getDateForPage(pageIndex);
                  return _SpCalendarMonthGrid(
                    year: date.year,
                    month: date.month,
                    cellBuilder: widget.cellBuilder,
                  );
                },
              ),
            );
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  /// Builds the header showing day names (Mon, Tue, etc.)
  Widget _buildDaysHeader(BuildContext context) {
    return Row(
      children: List.generate(DateTime.daysPerWeek, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                DateFormatHelper.E(DateTime(2000, 10, index + 1), context.locale),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: index == 0 || index == 6 ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Calculates the height needed for the calendar grid
  double _calculateCalendarHeight(BoxConstraints constraints) {
    final visibleDays = CalendarDaysGenerator.generate(
      year: _currentYear,
      month: _currentMonth,
    );
    final rows = (visibleDays.length / DateTime.daysPerWeek).ceil();
    return rows * constraints.maxWidth / DateTime.daysPerWeek; // 56 is the minimum height per row
  }
}
