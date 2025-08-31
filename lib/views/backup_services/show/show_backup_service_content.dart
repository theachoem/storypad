part of 'show_backup_service_view.dart';

class _ShowBackupServiceContent extends StatelessWidget {
  const _ShowBackupServiceContent(this.viewModel);

  final ShowBackupServiceViewModel viewModel;

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
              const TextSpan(text: "Google Drive "),
              WidgetSpan(
                child: Icon(MdiIcons.googleDrive),
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
                Text("theacheng.g6@gmail.com", style: TextTheme.of(context).titleMedium),
                Text("Last synced: August 12, 2025 11:00 AM", style: TextTheme.of(context).bodyMedium),
              ],
            ),
          ),
          const SpSectionTitle(title: "Folders"),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/years"),
            trailing: Text("100kb"),
          ),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/images"),
            trailing: Text("100mb"),
          ),
          const ListTile(
            leading: Icon(SpIcons.folderOpen),
            title: Text("appDataFolder/videos"),
            trailing: Text("200mb"),
          ),
          const ListTile(
            leading: Icon(Icons.file_present),
            title: Text("appDataFolder/manifest.json"),
            trailing: Text("0kb"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              label: const Text("Sign Out"),
              icon: const Icon(Icons.logout),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 8.0),
          const Divider(),
          ListTile(
            iconColor: ColorScheme.of(context).error,
            leading: const Icon(SpIcons.deleteForever),
            title: const Text("Delete"),
            subtitle: const Text("Permanent Delete from Google Drive"),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => const DeleteBackupProviderRoute().push(context),
          ),
        ],
      ),
    );
  }
}
