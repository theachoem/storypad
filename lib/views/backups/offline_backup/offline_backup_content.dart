part of 'offline_backup_view.dart';

class _OfflineBackupsContent extends StatelessWidget {
  const _OfflineBackupsContent(this.viewModel);

  final OfflineBackupsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.offline_backup.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0).add(
          EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
        ),
        children: [
          _Card(
            title: tr('list_tile.export_backup.title'),
            subtitle: tr('list_tile.export_backup.subtitle'),
            action: FilledButton.tonalIcon(
              icon: const Icon(SpIcons.exportOffline),
              label: Text(tr('button.export')),
              onPressed: context.read<BackupProvider>().lastDbUpdatedAt == null
                  ? null
                  : () => viewModel.export(context),
            ),
          ),
          const SizedBox(height: 12.0),
          _Card(
            title: tr('list_tile.import_backup.title'),
            subtitle: tr('list_tile.import_backup.subtitle', namedArgs: {'APP_NAME': kAppName}),
            action: FilledButton.tonalIcon(
              icon: const Icon(SpIcons.importOffline),
              label: Text(tr('button.import')),
              onPressed: () => viewModel.import(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextTheme.of(context).titleMedium,
            ),
            Text(
              subtitle,
              style: TextTheme.of(context).bodyMedium,
            ),
            const SizedBox(height: 8.0),
            action,
          ],
        ),
      ),
    );
  }
}
