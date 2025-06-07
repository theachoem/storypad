part of 'show_backup_view.dart';

class _ShowBackupContent extends StatelessWidget {
  const _ShowBackupContent(this.viewModel);

  final ShowBackupsViewModel viewModel;

  BackupObject get backup => viewModel.params.backup;

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
        icon: Icon(SpIcons.restore),
        label: Text(tr("button.restore")),
        onPressed: () => viewModel.restore(context),
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
            default:
              leadingIconData = SpIcons.table;
              translateTabledName = table.key;
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
