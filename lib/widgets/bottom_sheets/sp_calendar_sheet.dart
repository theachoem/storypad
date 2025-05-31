import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpCalendarSheet extends BaseBottomSheet {
  final int? initialMonth;
  final int? initialYear;

  SpCalendarSheet({
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView();
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        initialChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(),
          );
        },
      );
    }
  }

  CalendarView buildView() {
    return CalendarView(
      params: CalendarRoute(
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
    );
  }
}
