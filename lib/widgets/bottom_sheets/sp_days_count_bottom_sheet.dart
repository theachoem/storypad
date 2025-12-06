import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

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
          const SizedBox(height: 12.0),
          Text(
            tr("dialog.lookings_back.title"),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            plural("dialog.lookings_back.subtitle", story.dateDifferentCount.inDays),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ColorScheme.of(context).primary),
          ),
          const SizedBox(height: 12.0),
          buildShowTimeOnHomeCheckBox(),
        ],
      ),
    );
  }

  Widget buildShowTimeOnHomeCheckBox() {
    return SpSingleStateWidget.listen(
      initialValue: story.preferredShowDayCount,
      builder: (context, value, notifier) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: () {
              if (onToggleShowDayCount != null) {
                onToggleShowDayCount!();
                notifier.value = !value;
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                mainAxisSize: .min,
                spacing: 4.0,
                children: [
                  Checkbox.adaptive(
                    value: value,
                    onChanged: (newValue) {
                      if (onToggleShowDayCount != null) {
                        onToggleShowDayCount!();
                        notifier.value = newValue ?? false;
                      }
                    },
                  ),
                  Text(tr("button.show_day_count_on_home")),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
