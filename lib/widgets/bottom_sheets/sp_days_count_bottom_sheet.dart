import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_pin_to_home_button.dart';

class SpDaysCountBottomSheet extends BaseBottomSheet {
  final StoryDbModel story;
  final Future<void> Function()? onToggleShowDayCount;

  SpDaysCountBottomSheet({
    this.onToggleShowDayCount,
    required this.story,
  });

  @override
  bool get fullScreen => false;

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
          const SizedBox(height: 16.0),
          SpPinToHomeButton(
            pinned: story.preferredShowDayCount,
            disabled: onToggleShowDayCount == null,
            onPressed: () async {
              onToggleShowDayCount!();
              if (context.mounted) Navigator.maybePop(context);
            },
          ),
        ],
      ),
    );
  }
}
