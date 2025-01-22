import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/adapters/objectbox/preference_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/story_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/tag_box.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/string_extension.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backup/local_widgets/table_viewers/backup_preferences_table_viewer.dart';
import 'package:storypad/views/backup/local_widgets/table_viewers/backup_stories_table_viewer.dart';
import 'package:storypad/views/backup/local_widgets/table_viewers/backup_default_table_viewer.dart';
import 'package:storypad/views/backup/local_widgets/table_viewers/backup_tags_table_viewer.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class BackupObjectViewer extends StatelessWidget {
  const BackupObjectViewer({
    super.key,
    required this.backup,
  });

  final BackupObject backup;

  void restore(BuildContext context) {
    context.read<BackupProvider>().forceRestore(backup, context);
  }

  @override
  Widget build(BuildContext context) {
    String? backupAt = DateFormatService.yMEd_jmsNullable(backup.fileInfo.createdAt);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: backupAt != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.fileInfo.device.model,
                    style: TextTheme.of(context).titleSmall,
                  ),
                  Text(
                    backupAt,
                    style: TextTheme.of(context).bodyMedium,
                  ),
                ],
              )
            : Text(backup.fileInfo.device.model),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FilledButton.icon(
        icon: const Icon(Icons.restore),
        label: const Text("Restore"),
        onPressed: () => restore(context),
      ),
      body: ListView.builder(
        itemCount: backup.tables.length,
        itemBuilder: (context, index) {
          final table = backup.tables.entries.elementAt(index);
          final value = table.value;
          final documentCount = value is List ? value.length : 0;

          IconData leadingIconData;

          switch (table.key) {
            case 'stories':
              leadingIconData = Icons.library_books;
              break;
            case 'tags':
              leadingIconData = Icons.sell;
              break;
            case 'preferences':
              leadingIconData = MdiIcons.table;
              break;
            default:
              leadingIconData = MdiIcons.table;
              break;
          }

          return ListTile(
            leading: Icon(leadingIconData),
            title: Text(table.key.capitalize),
            subtitle: Text(documentCount > 1 ? '$documentCount rows' : '$documentCount row'),
            onTap: () {
              if (value is List) {
                List<Map<String, dynamic>> tableContents = value.whereType<Map<String, dynamic>>().toList();
                viewBackupObject(
                  tableName: table.key,
                  context: context,
                  tableContents: tableContents,
                );
              }
            },
          );
        },
      ),
    );
  }

  void viewBackupObject({
    required String tableName,
    required BuildContext context,
    required List<Map<String, dynamic>> tableContents,
  }) {
    Widget viewer;

    switch (tableName) {
      case 'stories':
        List<StoryDbModel> models = tableContents.map(StoryBox().modelFromJson).toList();
        viewer = BackupStoriesTableViewer(stories: models);
        break;
      case 'tags':
        List<TagDbModel> models = tableContents.map(TagBox().modelFromJson).toList();
        viewer = BackupTagsTableViewer(tags: models);
        break;
      case 'preferences':
        List<PreferenceDbModel> models = tableContents.map(PreferenceBox().modelFromJson).toList();
        viewer = BackupPreferencesTableViewer(preferences: models);
        break;
      default:
        viewer = BackupDefaultTableViewer(tableContents: tableContents);
        break;
    }

    SpNestedNavigation.maybeOf(context)?.push(Builder(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tableName.capitalize),
        ),
        body: viewer,
      );
    }));
  }
}
