import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backup_services/local_widgets/backup_service_tile.dart';
import 'package:storypad/views/import_export/import_export_view.dart';
import 'package:storypad/views/settings/local_widgets/asset_compression_tile.dart';
import 'package:storypad/views/storage_management/storage_management_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

class DataBackupRoute extends BaseRoute {
  const DataBackupRoute();

  @override
  Widget buildPage(BuildContext context) => const DataBackupView();
}

class DataBackupView extends StatelessWidget {
  const DataBackupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("general.data_backup"))),
      body: ListView(
        children: [
          SpSectionTitle(title: tr("general.cloud_backup")),
          ..._buildCloudServiceTiles(context),
          const Divider(),
          SpSectionTitle(title: tr("general.local_backup")),
          ListTile(
            leading: const Icon(SpIcons.exportOffline),
            title: Text(tr('general.export')),
            onTap: () => const ImportExportRoute(showExport: true).push(context),
          ),
          ListTile(
            leading: const Icon(SpIcons.importOffline),
            title: Text(tr('general.import')),
            onTap: () => const ImportExportRoute(showImport: true).push(context),
          ),
          const Divider(),
          SpSectionTitle(title: tr('general.storage')),
          ListTile(
            leading: const Icon(SpIcons.storage),
            title: Text(tr('page.storage_management.title')),
            onTap: () => const StorageManagementRoute().push(context),
          ),
          AssetCompressionTile.globalTheme(),
        ],
      ),
    );
  }

  List<Widget> _buildCloudServiceTiles(BuildContext context) {
    final tiles = <Widget>[];
    final services = context.read<BackupProvider>().services;

    for (int i = 0; i < services.length; i++) {
      tiles.add(BackupServiceTile(service: services[i]));
      if (i < services.length - 1) tiles.add(const Divider());
    }

    return tiles;
  }
}
