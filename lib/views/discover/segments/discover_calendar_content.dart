import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/calendar_days_generator.dart';
import 'package:storypad/core/services/month_picker_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

part './local_widgets/calendar_month_with_header.dart';
part './local_widgets/calendar_month_header.dart';
part './local_widgets/calendar_month.dart';

class DiscoverCalendarContent extends StatefulWidget {
  const DiscoverCalendarContent({
    super.key,
  });

  @override
  State<DiscoverCalendarContent> createState() => _DiscoverCalendarContentState();
}

class _DiscoverCalendarContentState extends State<DiscoverCalendarContent> {
  int month = DateTime.now().month;
  int year = DateTime.now().year;
  int selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverToBoxAdapter(
              child: _CalendarMonthWithHeader(
                month: month,
                year: year,
                selectedDay: selectedDay,
                onChanged: (year, month, selectedDay) {
                  setState(() {
                    this.year = year;
                    this.month = month;
                    this.selectedDay = selectedDay;
                  });
                },
              ),
            ),
          ];
        },
        body: SpStoryList.withQuery(
          disableMultiEdit: true,
          filter: SearchFilterObject(
            years: {},
            types: {PathType.archives},
            tagId: null,
            assetId: null,
          ),
        ),
      ),
    );
  }
}
