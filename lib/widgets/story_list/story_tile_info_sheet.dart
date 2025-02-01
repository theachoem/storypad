import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/date_format_service.dart';

class StoryTileInfoSheet {
  final StoryDbModel story;

  StoryTileInfoSheet({
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
                title: const Text('Story Date'),
                subtitle: Text(DateFormatService.yMEd(story.displayPathDate)),
              ),
              if (story.movedToBinAt != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Moved to bin'),
                  subtitle: Text(DateFormatService.yMEd_jm(story.movedToBinAt!)),
                ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Updated'),
                subtitle: Text(DateFormatService.yMEd_jm(story.updatedAt)),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Created'),
                subtitle: Text(DateFormatService.yMEd_jm(story.createdAt)),
              ),
            ],
          ),
        );
      },
    );
  }
}
