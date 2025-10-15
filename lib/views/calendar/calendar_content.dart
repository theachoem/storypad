part of 'calendar_view.dart';

class _CalendarContent extends StatelessWidget {
  const _CalendarContent(this.viewModel);

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (CupertinoSheetRoute.hasParentSheet(context)) {
      return Container(
        padding: const EdgeInsets.only(top: 12.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: buildScaffold(context),
      );
    } else {
      return buildScaffold(context);
    }
  }

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return switch (viewModel.selectedSegment) {
      CalendarSegmentId.mood => MoodCalendarView(
        monthYearNotifier: viewModel.monthYearNotifier,
      ),
      CalendarSegmentId.period => PeriodCalendarView(
        monthYearNotifier: viewModel.monthYearNotifier,
      ),
    };
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: ValueListenableBuilder(
        valueListenable: viewModel.monthYearNotifier,
        builder: (context, monthYear, child) {
          return SpTapEffect(
            onTap: () async {
              final result = await MonthPickerService(
                context: context,
                month: monthYear.month,
                year: monthYear.year,
              ).showPicker();
              if (result != null) {
                viewModel.onMonthYearChanged(result.year, result.month);
              }
            },
            child: Text(
              DateFormatHelper.yMMMM(DateTime(monthYear.year, monthYear.month, 1), context.locale),
              key: ValueKey("${monthYear.month}-${monthYear.year}"),
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          );
        },
      ),
      leading: IconButton(
        icon: const Icon(SpIcons.keyboardLeft),
        onPressed: () {
          final newMonth = viewModel.monthYearNotifier.value.month - 1 == 0
              ? 12
              : viewModel.monthYearNotifier.value.month - 1;

          final newYear = viewModel.monthYearNotifier.value.month - 1 == 0
              ? viewModel.monthYearNotifier.value.year - 1
              : viewModel.monthYearNotifier.value.year;

          viewModel.onMonthYearChanged(newYear, newMonth);
        },
      ),
      bottom: viewModel.segments.length > 1 ? buildSegmentButtons(context) : null,
      actions: [
        IconButton(
          icon: const Icon(SpIcons.keyboardRight),
          onPressed: () {
            final newMonth = viewModel.monthYearNotifier.value.month + 1 == 13
                ? 1
                : viewModel.monthYearNotifier.value.month + 1;

            final newYear = viewModel.monthYearNotifier.value.month + 1 == 13
                ? viewModel.monthYearNotifier.value.year + 1
                : viewModel.monthYearNotifier.value.year;

            viewModel.onMonthYearChanged(newYear, newMonth);
          },
        ),
      ],
    );
  }

  PreferredSizeWidget buildSegmentButtons(BuildContext context) {
    Widget segmentButton;

    if (kIsCupertino) {
      segmentButton = CupertinoSlidingSegmentedControl<CalendarSegmentId>(
        groupValue: viewModel.selectedSegment,
        onValueChanged: (segment) {
          if (segment != null) {
            viewModel.onSegmentChanged(segment);
          }
        },
        children: {
          for (final segment in viewModel.segments) segment: Text(segment.translatedName(context)),
        },
      );
    } else {
      segmentButton = SegmentedButton<CalendarSegmentId>(
        selected: {viewModel.selectedSegment},
        multiSelectionEnabled: false,
        onSelectionChanged: (value) {
          if (value.isNotEmpty) {
            viewModel.onSegmentChanged(value.first);
          }
        },
        showSelectedIcon: false,
        segments: [
          for (final segment in viewModel.segments)
            ButtonSegment<CalendarSegmentId>(
              value: segment,
              label: Text(segment.translatedName(context)),
            ),
        ],
      );
    }

    return PreferredSize(
      preferredSize: CupertinoSheetRoute.hasParentSheet(context)
          ? const Size.fromHeight(32.0)
          : const Size.fromHeight(48.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          width: double.infinity,
          child: segmentButton,
        ),
      ),
    );
  }
}
