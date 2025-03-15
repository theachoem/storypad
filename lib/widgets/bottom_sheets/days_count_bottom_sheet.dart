import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class DaysCountBottomSheet extends BaseBottomSheet {
  final StoryDbModel story;
  final Future<void> Function()? onToggleShowDayCount;

  DaysCountBottomSheet({
    this.onToggleShowDayCount,
    required this.story,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr("dialog.lookings_back.title"),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            plural("dialog.lookings_back.subtitle", story.dateDifferentCount.inDays),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ColorScheme.of(context).primary),
          ),
          SizedBox(height: 16.0),
          OutlinedButton.icon(
            icon: Icon(story.preferredShowDayCount ? MdiIcons.pinOff : MdiIcons.pin,
                color: ColorScheme.of(context).primary),
            label: Text(story.preferredShowDayCount ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
            onPressed: onToggleShowDayCount == null
                ? null
                : () async {
                    onToggleShowDayCount!();
                    if (context.mounted) Navigator.maybePop(context);
                  },
          ),
        ],
      ),
    );
  }
}
