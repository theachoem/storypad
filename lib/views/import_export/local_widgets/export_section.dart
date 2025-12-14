part of '../import_export_view.dart';

class _ExportSection extends StatefulWidget {
  const _ExportSection({
    required this.viewModel,
  });

  final ImportExportViewModel viewModel;

  @override
  State<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends State<_ExportSection> {
  AppExportOption selectedOption = .storyPadJson;

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: selectedOption,
      onChanged: (AppExportOption? value) {
        if (value != null) {
          setState(() {
            selectedOption = value;
          });
        }
      },
      child: Column(
        children: [
          buildExportHeader(context),
          RadioListTile(
            secondary: const Icon(SpIcons.importOffline),
            title: Text(tr('list_tile.export_storypad_json.title')),
            subtitle: const Text('Native format preserving all data & metadata'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            value: AppExportOption.storyPadJson,
          ),
          RadioListTile(
            secondary: Icon(SpIcons.markdown),
            title: const Text('Export Markdown (.md)'),
            subtitle: const Text('Compatible with Obsidian, Notion, and markdown editors.'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            value: AppExportOption.markdown,
          ),
          RadioListTile(
            secondary: Icon(SpIcons.pdf),
            title: const Text('Export PDF (.pdf)'),
            subtitle: const Text('Shareable document with images and formatting.'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            value: AppExportOption.pdf,
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FilledButton(
              child: const Text("Export"),
              onPressed: () => widget.viewModel.export(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExportHeader(BuildContext context) {
    return SpSectionTitle(
      title: tr('general.export'),
      trailing: SpTapEffect(
        onTap: () async {
          final result = await SearchFilterRoute(
            resetTune: widget.viewModel.initialExportFilter,
            initialTune: widget.viewModel.exportFilter,
            filterTagModifiable: true,
            multiSelectYear: true,
          ).push(context);

          if (result is SearchFilterObject) {
            widget.viewModel.setExportFilter(result);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          spacing: 8.0,
          children: [
            Text(
              [
                plural('plural.story', widget.viewModel.storyCount ?? 0),
                if (!widget.viewModel.filtered) '(${tr('general.all')})',
              ].join(' '),
            ),
            Icon(SpIcons.tune),
          ],
        ),
      ),
    );
  }
}
