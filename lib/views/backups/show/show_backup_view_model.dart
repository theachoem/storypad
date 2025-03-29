import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/tables/show/show_table_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'show_backup_view.dart';

class ShowBackupsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowBackupsRoute params;

  ShowBackupsViewModel({
    required this.params,
  });

  void restore(BuildContext context) {
    context.read<BackupProvider>().forceRestore(params.backup, context);
  }

  void viewBackupContent({
    required dynamic value,
    required String translateTabledName,
    required String tableName,
    required BuildContext context,
  }) async {
    if (value is List) {
      List<Map<String, dynamic>> tableContents = value.whereType<Map<String, dynamic>>().toList();
      ShowTableRoute(
        translateTabledName: translateTabledName,
        tableName: tableName,
        context: context,
        tableContents: tableContents,
      ).push(context);
    }
  }
}
