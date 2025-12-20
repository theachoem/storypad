part of 'export_assets_view.dart';

class _ExportAssetsContent extends StatelessWidget {
  const _ExportAssetsContent(this.viewModel);

  final ExportAssetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            text: tr('button.export_assets'),
            children: [
              if (context.locale.languageCode != 'en')
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: ColorScheme.of(context).readOnly.surface2,
                    ),
                    child: Text(
                      'EN',
                      style: TextTheme.of(context).labelMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: MediaQuery.paddingOf(
          context,
        ).copyWith(top: 16.0, bottom: 16.0).add(const EdgeInsets.symmetric(horizontal: 16.0)),
        children: [
          buildStatistics(context),
          const SizedBox(height: 12.0),
          buildExportButton(context),
          const SizedBox(height: 12.0),
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SpMarkdownBody(
                body: '''
Media files are exported separately from stories for flexibility and smaller file sizes.

**How it works:**
- Any files stored in the cloud will be downloaded to your device first
- Make sure you have enough free storage space before exporting
- All your images and audio files are packaged into a single compressed file (.tar.gz)

**Export Structure:**
```
images/
    ├── 001.jpg
    ├── 002.png
    └── ...
audio/
    ├── 001.m4a
    ├── 002.m4a
    └── ...
```
          ''',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatistics(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Media',
              style: TextTheme.of(context).titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            ...AssetType.values.map((type) {
              final total = viewModel.assetCountsByType[type] ?? 0;
              final downloaded = viewModel.downloadedCountsByType[type] ?? 0;

              return _buildStatRow(
                context,
                type == AssetType.image ? SpIcons.photo : SpIcons.voice,
                '${type.name.substring(0, 1).toUpperCase()}${type.name.substring(1)}s',
                '$downloaded / $total',
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              label,
              style: TextTheme.of(context).bodyMedium,
            ),
          ),
          Text(
            value,
            style: TextTheme.of(context).bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExportButton(BuildContext context) {
    if (viewModel.isDownloading) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator.adaptive(),
        ),
        label: const Text('Downloading...'),
      );
    }

    return FilledButton.icon(
      onPressed: () => viewModel.exportAssets(context),
      icon: const Icon(SpIcons.exportOffline),
      label: const Text('Export (.tar.gz)'),
    );
  }
}
