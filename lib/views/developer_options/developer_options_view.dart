import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/views/developer_options/recently_deleted_records/recently_deleted_records_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_logs_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class DeveloperOptionsRoute extends BaseRoute {
  const DeveloperOptionsRoute();

  @override
  Widget buildPage(BuildContext context) => DeveloperOptionsView(params: this);
}

class DeveloperOptionsView extends StatelessWidget {
  const DeveloperOptionsView({
    super.key,
    required this.params,
  });

  final DeveloperOptionsRoute params;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Options"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(SpIcons.table),
            title: const Text("Delete Records"),
            subtitle: const Text(
              "For safety, permanently deleted records are kept on your device for 7 days "
              "(and are not backed up to the cloud). "
              "To remove them immediately, clear the app cache.",
            ),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => const RecentlyDeletedRecordsRoute().push(context),
          ),
          ListTile(
            leading: const Icon(SpIcons.info),
            title: const Text("See Debug Logs"),
            subtitle: const Text("View the app debug logs."),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => SpShareLogsBottomSheet().show(context: context),
          ),
          const Divider(),
          ...SupportDirectoryPath.values.where((path) => path.directory.existsSync()).map((supportPath) {
            bool allowedToDelete =
                supportPath != SupportDirectoryPath.objectbox &&
                supportPath != SupportDirectoryPath.audio &&
                supportPath != SupportDirectoryPath.images;
            return ListTile(
              leading: const Icon(SpIcons.folderOpen),
              title: Text("Folder: ${supportPath.relativePath}"),
              subtitle: Text(
                "Size: ${supportPath.directory.listSync().map((e) => e.statSync().size).fold<int>(0, (a, b) => a + b) ~/ 1024} KB",
              ),
              trailing: allowedToDelete ? Icon(SpIcons.delete, color: ColorScheme.of(context).error) : null,
              onTap: !allowedToDelete
                  ? null
                  : () async {
                      final result = await showOkCancelAlertDialog(
                        context: context,
                        isDestructiveAction: true,
                        title: 'Delete Folder',
                        okLabel: 'Delete',
                        message: [
                          'Are you sure you want to delete "${supportPath.relativePath}" & all its contents?',
                          'Make sure you have backed up any important data before proceeding.',
                          'This action cannot be undone.',
                        ].join("\n\n"),
                      );

                      if (result == OkCancelResult.ok) {
                        await supportPath.directory.delete(recursive: true);
                        if (context.mounted) Navigator.maybePop(context);
                      }
                    },
            );
          }),
        ],
      ),
    );
  }
}
