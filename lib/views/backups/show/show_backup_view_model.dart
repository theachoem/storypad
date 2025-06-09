import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/backups/tables/show/show_table_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/home/home_view.dart';
import 'show_backup_view.dart';

class ShowBackupsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowBackupsRoute params;

  ShowBackupsViewModel({
    required this.params,
  });

  void restore(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#forceRestore',
      future: () => RestoreBackupService.appInstance.forceRestore(backup: params.backup),
    );

    if (!context.mounted) return;
    AnalyticsService.instance.logForceRestoreBackup(backupFileInfo: params.backup.fileInfo);

    await context.read<TagsProvider>().reload();
    await HomeView.reload(debugSource: '$runtimeType#forceRestore');

    if (!context.mounted) return;
    MessengerService.of(context).showSnackBar(tr("snack_bar.force_restore_success"));
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
