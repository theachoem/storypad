import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

class StoryInfoSheet {
  final StoryDbModel story;

  StoryInfoSheet({
    required this.story,
  });

  Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
          child: Column(
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
            ],
          ),
        );
      },
    );
  }
}
