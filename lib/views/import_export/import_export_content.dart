part of 'import_export_view.dart';

class _ImportExportContent extends StatelessWidget {
  const _ImportExportContent(this.viewModel);

  final ImportExportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final onlyExport = viewModel.params.showExport == true && viewModel.params.showImport != true;
    final onlyImport = viewModel.params.showImport == true && viewModel.params.showExport != true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          onlyExport
              ? tr('general.export')
              : onlyImport
              ? tr('general.import')
              : tr('page.import_export_backup'),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16.0),
          if (!onlyExport) ...[
            if (!onlyImport) SpSectionTitle(title: tr('general.import')),
            ListTile(
              leading: const Icon(SpIcons.importOffline),
              title: Text(tr('list_tile.import_storypad_json.title')),
              onTap: () => viewModel.import(context),
            ),
            ListTile(
              leading: const Icon(SpIcons.photo),
              title: Text(tr('list_tile.import_media.title')),
              onTap: () => viewModel.importMedia(context),
            ),
            // TODO: more import options with files support + export by date & export in PDF
            // ListTile(
            //   leading: const Icon(SpIcons.importOffline),
            //   title: const Text("Import StoryPad JSON (.zip)"),
            //   onTap: () => viewModel.import(context),
            // ),
            // ListTile(
            //   leading: const Icon(SpIcons.importOffline),
            //   title: const Text("Import DayOne JSON (.zip)"),
            //   onTap: () {},
            // ),
            // ListTile(
            //   leading: const Icon(SpIcons.importOffline),
            //   title: const Text("Import Journey JSON (.zip)"),
            //   onTap: () {},
            // ),
          ],
          if (!onlyExport && !onlyImport) const Divider(),
          if (!onlyImport) _ExportSection(viewModel: viewModel),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.0),
        ],
      ),
    );
  }
}
