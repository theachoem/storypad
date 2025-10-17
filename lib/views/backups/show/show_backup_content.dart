part of 'show_backup_view.dart';

class _ShowBackupContent extends StatelessWidget {
  const _ShowBackupContent(this.viewModel);

  final ShowBackupsViewModel viewModel;

  BackupObject get backup => viewModel.params.backup;

  @override
  Widget build(BuildContext context) {
    String? backupAt = DateFormatHelper.yMEd_jmNullable(backup.fileInfo.createdAt, context.locale);

    String? sizeInKB;

    if (backup.originalFileSize != null) {
      sizeInKB = "${(backup.originalFileSize! / 1024).toStringAsFixed(2)}kb";
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: backupAt != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      backup.fileInfo.device.model,
                      sizeInKB,
                    ].join(" - "),
                    style: TextTheme.of(context).titleSmall,
                  ),
                  Text(
                    backupAt,
                    style: TextTheme.of(context).bodyMedium,
                  ),
                ],
              )
            : Text(backup.fileInfo.device.model),

        actions: [
          SpPopupMenuButton(
            items: (context) {
              return [
                SpPopMenuItem(
                  titleStyle: TextStyle(color: ColorScheme.of(context).error),
                  leadingIconData: SpIcons.refresh,
                  title: tr('button.restore'),
                  onPressed: () => viewModel.restore(context),
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                onPressed: callback,
                icon: const Icon(SpIcons.moreVert),
              );
            },
          ),
        ],
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
              leadingIconData = SpIcons.book;
              translateTabledName = tr("general.stories");
              break;
            case 'tags':
              leadingIconData = SpIcons.tag;
              translateTabledName = tr("general.tags");
              break;
            case 'preferences':
              leadingIconData = SpIcons.table;
              translateTabledName = tr("general.preferences");
              break;
            case 'assets':
              leadingIconData = SpIcons.table;
              translateTabledName = tr("general.assets");
              break;
            case 'templates':
              leadingIconData = SpIcons.lightBulb;
              translateTabledName = tr("add_ons.templates.title");
              break;
            case 'relax_sound_mixes':
              leadingIconData = SpIcons.musicNote;
              translateTabledName = tr("general.sound_mixes");
              break;
            case 'events':
              leadingIconData = SpIcons.calendar;
              translateTabledName = table.key.capitalize;
              break;
            default:
              leadingIconData = SpIcons.table;
              translateTabledName = table.key.capitalize;
              break;
          }

          return ListTile(
            leading: Icon(leadingIconData),
            title: Text(translateTabledName),
            subtitle: Text(plural("plural.row", documentCount)),
            onTap: () => viewModel.viewBackupContent(
              value: value,
              translateTabledName: translateTabledName,
              tableName: tableName,
              context: context,
            ),
          );
        },
      ),
    );
  }
}
