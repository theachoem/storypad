import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/tags_box.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/local_widgets/table_viewers/backup_assets_table_viewer.dart';
import 'package:storypad/views/backups/local_widgets/table_viewers/backup_preferences_table_viewer.dart';
import 'package:storypad/views/backups/local_widgets/table_viewers/backup_stories_table_viewer.dart';
import 'package:storypad/views/backups/local_widgets/table_viewers/backup_default_table_viewer.dart';
import 'package:storypad/views/backups/local_widgets/table_viewers/backup_tags_table_viewer.dart';
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
    String? backupAt = DateFormatHelper.yMEd_jmNullable(backup.fileInfo.createdAt, context.locale);

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
        label: Text(tr("button.restore")),
        onPressed: () => restore(context),
      ),
      body: ListView.builder(
        itemCount: backup.tables.length,
        itemBuilder: (context, index) {
          final table = backup.tables.entries.elementAt(index);
          final value = table.value;
          final documentCount = value is List ? value.length : 0;

          IconData leadingIconData;
          String tableName = table.key;
          String translateTabledName;

          switch (table.key) {
            case 'stories':
              leadingIconData = Icons.library_books;
              translateTabledName = tr("general.stories");
              break;
            case 'tags':
              leadingIconData = Icons.sell;
              translateTabledName = tr("general.tags");
              break;
            case 'preferences':
              leadingIconData = MdiIcons.table;
              translateTabledName = tr("general.preferences");
              break;
            case 'assets':
              leadingIconData = MdiIcons.table;
              translateTabledName = tr("general.assets");
              break;
            default:
              leadingIconData = MdiIcons.table;
              translateTabledName = table.key;
              break;
          }

          return ListTile(
            leading: Icon(leadingIconData),
            title: Text(translateTabledName),
            subtitle: Text(plural("plural.row", documentCount)),
            onTap: () {
              if (value is List) {
                List<Map<String, dynamic>> tableContents = value.whereType<Map<String, dynamic>>().toList();
                viewBackupObject(
                  translateTabledName: translateTabledName,
                  tableName: tableName,
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
    required String translateTabledName,
    required BuildContext context,
    required List<Map<String, dynamic>> tableContents,
  }) {
    Widget viewer;

    switch (tableName) {
      case 'stories':
        List<StoryDbModel> models =
            tableContents.map((e) => StoriesBox().modelFromJson(e)..markAsCloudViewing()).toList();
        viewer = BackupStoriesTableViewer(stories: models);
        break;
      case 'tags':
        List<TagDbModel> models = tableContents.map((e) => TagsBox().modelFromJson(e)..markAsCloudViewing()).toList();
        viewer = BackupTagsTableViewer(tags: models);
        break;
      case 'preferences':
        List<PreferenceDbModel> models =
            tableContents.map((e) => PreferencesBox().modelFromJson(e)..markAsCloudViewing()).toList();
        viewer = BackupPreferencesTableViewer(preferences: models);
        break;
      case 'assets':
        List<AssetDbModel> models =
            tableContents.map((e) => AssetsBox().modelFromJson(e)..markAsCloudViewing()).toList();
        viewer = BackupAssetsTableViewer(assets: models);
        break;
      default:
        viewer = BackupDefaultTableViewer(tableContents: tableContents);
        break;
    }

    SpNestedNavigation.maybeOf(context)?.push(Builder(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(translateTabledName),
        ),
        body: viewer,
      );
    }));
  }
}
