part of 'backup_services_view.dart';

class _BackupServicesContent extends StatelessWidget {
  const _BackupServicesContent(this.viewModel);

  final BackupServicesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backup"),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16.0),
          const SpSectionTitle(title: "Providers"),
          ListTile(
            leading: SizedBox(
              height: double.infinity,
              child: Icon(MdiIcons.googleDrive),
            ),
            title: const Text("Google Drive"),
            isThreeLine: true,
            trailing: SizedBox(
              height: double.infinity,
              child: Icon(
                SpIcons.cloudDone,
                color: ColorScheme.of(context).bootstrap.success.color,
              ),
            ),
            subtitle: Text([
              "theacheng.g6@gmail.com",
              "Last synced: August 12, 2025 11:51am",
            ].join("\n")),
            onTap: () => const ShowBackupServiceRoute().push(context),
          ),
          ListTile(
            leading: Icon(MdiIcons.appleIcloud),
            title: const Text("iCloud"),
            subtitle: const Text("Disabled"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.dataset_linked),
            title: const Text("Self-Hosted"),
            subtitle: const Text("Disabled"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text("Import / Export"),
            onTap: () => const ImportExportRoute().push(context),
          ),
        ],
      ),
    );
  }
}
