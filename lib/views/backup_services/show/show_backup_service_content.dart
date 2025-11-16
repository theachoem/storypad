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
              TextSpan(text: "${viewModel.metadata.displayName} "),
              WidgetSpan(child: Icon(viewModel.metadata.icon)),
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
          const SpSectionTitle(title: "Folders"),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/backups"),
            trailing: Text("100kb"),
          ),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/images"),
            trailing: Text("100mb"),
          ),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/audio"),
            trailing: Text("50mb"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              label: const Text("Sign Out"),
              icon: const Icon(Icons.logout),
              onPressed: () => viewModel.params.service.signOut(),
            ),
          ),
          const SizedBox(height: 8.0),
          const Divider(),
          ListTile(
            iconColor: ColorScheme.of(context).error,
            leading: const Icon(SpIcons.deleteForever),
            title: const Text("Delete"),
            subtitle: Text(
              "Permanent Delete from ${viewModel.metadata.displayName}",
            ),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => const DeleteBackupProviderRoute().push(context),
          ),
        ],
      ),
    );
  }
}
