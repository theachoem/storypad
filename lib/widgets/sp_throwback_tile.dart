import 'package:easy_localization/easy_localization.dart' show BuildContextEasyLocalizationExtension, tr;
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart' show DateFormatHelper;
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/views/throwback/throwback_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart' show SpTapEffect;

class SpThrowbackTile extends StatelessWidget {
  const SpThrowbackTile({
    super.key,
    required this.throwbackDates,
  });

  final List<DateTime>? throwbackDates;
  DateTime get throwbackRepresentDate => throwbackDates?.firstOrNull ?? DateTime.now();

  Future<void> view(BuildContext context) {
    return ThrowbackRoute(
      day: throwbackRepresentDate.day,
      month: throwbackRepresentDate.month,
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    bool hasLastYearThrowback = throwbackDates?.any((e) => e.year == DateTime.now().year - 1) == true;

    String title;
    String subtitle = DateFormatHelper.yMEd(throwbackRepresentDate, context.locale);

    if (throwbackRepresentDate.year != DateTime.now().year) {
      title = tr('list_tile.throwback.for_selected_date');
    } else if (hasLastYearThrowback) {
      title = tr('list_tile.throwback.a_year_ago_title');
    } else {
      title = tr('list_tile.throwback.a_few_year_ago_title');
    }

    return SpTapEffect(
      onTap: () => view(context),
      child: buildContent(context, title, subtitle),
    );
  }

  Widget buildContent(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16.0,
        children: [
          buildMonogram(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextTheme.of(context).titleMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextTheme.of(context).bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                OutlinedButton(
                  child: Text(tr('button.view')),
                  onPressed: () => view(context),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonogram(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 6.0),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: ColorFromDayService(context: context).get(throwbackRepresentDate.weekday)!,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        SpIcons.history,
        color: ColorFromDayService(context: context).get(throwbackRepresentDate.weekday)!,
        size: 22.0,
      ),
    );
  }
}
