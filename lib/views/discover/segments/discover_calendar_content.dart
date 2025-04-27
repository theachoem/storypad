import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/calendar_days_generator.dart';
import 'package:storypad/core/services/month_picker_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

part 'local_widgets/calendar_month.dart';
part 'local_widgets/calendar_month_header.dart';
part 'local_widgets/calendar_date.dart';

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

  Map<int, String?> feelingMapByDay = {};
  int editedKey = 0;

  @override
  void initState() {
    super.initState();

    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
    StoryDbModel.db.addGlobalListener(reloadFeeling);
  }

  @override
  void dispose() {
    StoryDbModel.db.removeGlobalListener(reloadFeeling);
    super.dispose();
  }

  // only reload feeling when listen to DB.
  // story query list already know how to refresh their own list, so we don't have to refresh for them.
  Future<void> reloadFeeling() async {
    feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
    setState(() {});
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(
      id: null,
      initialYear: year,
      initialMonth: month,
      initialDay: selectedDay,
    ).push(context);

    editedKey += 1;
    setState(() {});

    Future.delayed(const Duration(seconds: 1)).then((_) {
      HomeView.reload(debugSource: '$runtimeType#goToNewPage');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: tr("button.new_story"),
        child: const Icon(SpIcons.newStory),
        onPressed: () => goToNewPage(context),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverToBoxAdapter(
              child: _CalendarMonth(
                month: month,
                year: year,
                selectedDay: selectedDay,
                feelingMapByDay: feelingMapByDay,
                onChanged: (year, month, selectedDay) {
                  setState(() {
                    this.selectedDay = year != this.year || month != this.month ? 1 : selectedDay;
                    this.year = year;
                    this.month = month;

                    if (year != this.year || month != this.month) {
                      feelingMapByDay = StoryDbModel.db.getStoryFeelingByMonth(month: month, year: year);
                    }
                  });
                },
              ),
            ),
          ];
        },
        body: Builder(builder: (context) {
          return SpStoryList.withQuery(
            key: ValueKey(editedKey),
            disableMultiEdit: true,
            filter: SearchFilterObject(
              years: {year},
              month: month,
              day: selectedDay,
              types: {PathType.docs},
              tagId: null,
              assetId: null,
            ),
          );
        }),
      ),
    );
  }
}
