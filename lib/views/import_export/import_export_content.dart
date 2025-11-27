part of 'import_export_view.dart';

class _ImportExportContent extends StatelessWidget {
  const _ImportExportContent(this.viewModel);

  final ImportExportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.import_export_backup')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16.0),
          SpSectionTitle(title: tr('general.import')),
          ListTile(
            leading: const Icon(SpIcons.importOffline),
            title: Text(tr('list_tile.import_storypad_json.title')),
            onTap: () => viewModel.import(context),
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
          const Divider(),
          SpSectionTitle(title: tr('general.export')),
          // ListTile(
          //   leading: const Icon(SpIcons.calendar),
          //   title: const Text("Date"),
          //   contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 12.0),
          //   trailing: const Row(
          //     mainAxisSize: MainAxisSize.min,
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text("All Entries"),
          //       Icon(SpIcons.dropDown),
          //     ],
          //   ),
          //   onTap: () {},
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FilledButton(
              child: Text(tr('list_tile.export_storypad_json.title')),
              onPressed: () => viewModel.export(context),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: OutlinedButton(
          //     child: const Text("Export PDF"),
          //     onPressed: () {},
          //   ),
          // ),
        ],
      ),
    );
  }
}
