import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/month_recap_stats_object.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/views/stats/stats_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

/// Minimal stats block embedded at each month header on the timeline.
///
/// The low-stakes "momentum nudge": leads with monthly coverage (active days
/// out of the month) and a compact muted line of pluralized counts. Tapping
/// opens the dedicated stats screen.
///
/// All numbers come from [stats]; the model owns formatting/localization so
/// this widget just renders and joins the labels.
class StoryMonthRecapTile extends StatelessWidget {
  const StoryMonthRecapTile({
    super.key,
    required this.story,
    required this.stats,
  });

  final StoryDbModel story;
  final MonthRecapStatsObject stats;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: SpTapEffect(
        onTap: () {
          if (context.read<InAppPurchaseProvider>().isProUser) {
            StatsRoute.month(story.displayPathDate).push(context);
          } else {
            const PaywallRoute(initialFocus: .stats).push(context);
          }
        },
        child: ListTile(
          leading: Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.bootstrap.warning.color, width: 1.0),
            ),
            child: Icon(SpIcons.star, size: 20.0, color: colorScheme.bootstrap.warning.color),
          ),
          title: Text(stats.titleLabel(context.locale)),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: stats.activeDaysLabel),
                TextSpan(
                  text: " · ${stats.labels.join(" · ")}",
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
