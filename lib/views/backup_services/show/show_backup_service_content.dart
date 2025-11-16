part of 'show_backup_service_view.dart';

class _ShowBackupServiceContent extends StatelessWidget {
  final ShowBackupServiceViewModel viewModel;

  const _ShowBackupServiceContent(this.viewModel);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: RichText(
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            style: TextTheme.of(context).titleLarge,
            children: [
              TextSpan(text: "${viewModel.serviceType.displayName} "),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(viewModel.serviceType.icon, size: 20),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.params.service.currentUser?.email ?? "Not signed in",
                  style: TextTheme.of(context).titleMedium,
                ),
                Text(
                  "Last synced: ${viewModel.params.service.currentUser?.refreshedAt ?? 'Never'}",
                  style: TextTheme.of(context).bodyMedium,
                ),
              ],
            ),
          ),
          if (viewModel.yearlyBackups == null)
            const CircularProgressIndicator.adaptive()
          else ...[
            const SpSectionTitle(title: "Backups (by created year)"),
            for (MapEntry<int, CloudFileObject> entry in viewModel.yearlyBackups?.entries ?? {})
              SpPopupMenuButton(
                items: (context) {
                  return [
                    SpPopMenuItem(
                      title: tr("button.view"),
                      leadingIconData: SpIcons.info,
                      onPressed: () => viewModel.openCloudFile(context, entry.value),
                    ),
                    SpPopMenuItem(
                      title: tr("button.delete"),
                      leadingIconData: SpIcons.delete,
                      titleStyle: TextStyle(color: ColorScheme.of(context).error),
                      onPressed: () async {
                        OkCancelResult userResponse = await showOkCancelAlertDialog(
                          context: context,
                          title: tr("dialog.are_you_sure_to_delete_this_backup.title"),
                          message: tr("dialog.are_you_sure.you_cant_undo_message"),
                          isDestructiveAction: true,
                          okLabel: tr("button.delete"),
                        );

                        if (userResponse == OkCancelResult.ok && context.mounted) {
                          await viewModel.deleteCloudFile(context, entry.value);
                        }
                      },
                    ),
                  ];
                },
                builder: (callback) {
                  return ListTile(
                    leading: const Icon(SpIcons.folderOpen),
                    title: Text(entry.key.toString()),
                    subtitle: Text(
                      entry.value.getFileInfo()?.device.model ??
                          entry.value.getFileInfo()?.device.id ??
                          tr("general.unknown"),
                    ),
                    trailing: Text(
                      DateFormatHelper.yMEd_jmNullable(entry.value.getFileInfo()?.createdAt, context.locale) ??
                          tr("general.na"),
                    ),
                    onTap: callback,
                  );
                },
              ),
          ],

          // We want to display actual files in store in each service instead,
          // but because limitation with API, we will show all backups for now.
          // const ListTile(
          //   leading: Icon(SpIcons.folderOpen),
          //   title: Text("appDataFolder/backups"),
          //   trailing: Text("100kb"),
          // ),
          // const ListTile(
          //   leading: Icon(SpIcons.folderOpen),
          //   title: Text("appDataFolder/images"),
          //   trailing: Text("100mb"),
          // ),
          // const ListTile(
          //   leading: Icon(SpIcons.folderOpen),
          //   title: Text("appDataFolder/audio"),
          //   trailing: Text("50mb"),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: ColorScheme.of(context).error),
              label: Text(tr('button.sign_out')),
              icon: const Icon(Icons.logout),
              onPressed: () => viewModel.signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
