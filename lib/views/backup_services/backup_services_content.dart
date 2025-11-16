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
          const SizedBox(height: 8.0),
          const GoogleDriveTile(),
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
