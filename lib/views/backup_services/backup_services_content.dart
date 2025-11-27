part of 'backup_services_view.dart';

class _BackupServicesContent extends StatelessWidget {
  const _BackupServicesContent(this.viewModel);

  final BackupServicesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.backups.title')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8.0),
          ..._buildCloudServiceTiles(context),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(tr('page.import_export_backup')),
            onTap: () => const ImportExportRoute().push(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCloudServiceTiles(BuildContext context) {
    final tiles = <Widget>[];

    for (int i = 0; i < viewModel.services.length; i++) {
      tiles.add(BackupServiceTile(service: viewModel.services[i]));
      if (i < viewModel.services.length - 1) tiles.add(const Divider());
    }

    return tiles;
  }
}
