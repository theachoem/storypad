import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpStoryInfoSheet extends BaseBottomSheet {
  final StoryDbModel story;

  SpStoryInfoSheet({
    required this.story,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(tr('list_tile.story_date.title')),
            subtitle: Text(DateFormatHelper.yMEd(story.displayPathDate, context.locale)),
          ),
          if (story.movedToBinAt != null)
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(tr('list_tile.moved_to_bin_at.title')),
              subtitle: Text(DateFormatHelper.yMEd_jm(story.movedToBinAt!, context.locale)),
            ),
          ListTile(
            leading: const Icon(Icons.update),
            title: Text(tr("list_tile.updated_at.title")),
            subtitle: Text(DateFormatHelper.yMEd_jm(story.updatedAt, context.locale)),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(tr("list_tile.created_at.title")),
            subtitle: Text(DateFormatHelper.yMEd_jm(story.createdAt, context.locale)),
          ),
          buildBottomPadding(bottomPadding),
        ],
      ),
    );
  }
}
