part of 'offline_backup_view.dart';

class _OfflineBackupsContent extends StatelessWidget {
  const _OfflineBackupsContent(this.viewModel);

  final OfflineBackupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offline Backup"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _Card(
            title: "Export Backup",
            subtitle: "Save stories to your device offline",
            action: FilledButton.tonalIcon(
              icon: Icon(Icons.download),
              label: Text("Export"),
              onPressed:
                  context.read<BackupProvider>().lastDbUpdatedAt == null ? null : () => viewModel.export(context),
            ),
          ),
          SizedBox(height: 12.0),
          _Card(
            title: "Import Backup",
            subtitle: "Import backup from your device into $kAppName",
            action: FilledButton.tonalIcon(
              icon: Icon(Icons.folder_open),
              label: Text("Import"),
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
            SizedBox(height: 8.0),
            action,
          ],
        ),
      ),
    );
  }
}
