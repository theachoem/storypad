part of 'paywalls_view.dart';

class _PaywallsContent extends StatelessWidget {
  const _PaywallsContent(this.viewModel);

  final PaywallsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorScheme.of(context).readOnly.surface1,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
      ),
      body: buildBody(context),
      bottomNavigationBar: _Offers(viewModel: viewModel),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.offers == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          children: [
            Assets.images.storypadLogo512x512.image(
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 12.0),
            Text(
              "Go Beyond Writing with",
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleMedium,
            ),
            Text(
              "StoryPad Premium",
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Available in August 2025',
              textAlign: TextAlign.center,
              style: TextTheme.of(context).bodyMedium?.copyWith(decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'We\'re still shaping these features. Some may evolve, and a few might even become free for everyone.',
                textAlign: TextAlign.center,
                style: TextTheme.of(context).bodyMedium,
              ),
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: buildTable(context),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context) {
    return DataTable(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      columns: const [
        DataColumn(label: Text('Feature'), columnWidth: FlexColumnWidth(1)),
        DataColumn(label: Text('Free')),
        DataColumn(label: Text('Pro')),
      ],
      rows: [
        DataRow(cells: [
          const DataCell(Text('Reminder')),
          DataCell(Icon(Icons.check, color: ColorScheme.of(context).bootstrap.success.color)),
          const DataCell(SizedBox.shrink()),
        ]),
        DataRow(cells: [
          const DataCell(Text('Throwback')),
          DataCell(Icon(Icons.check, color: ColorScheme.of(context).bootstrap.success.color)),
          const DataCell(SizedBox.shrink()),
        ]),
        DataRow(cells: [
          const DataCell(Text('Statistic')),
          DataCell(Icon(Icons.check, color: ColorScheme.of(context).bootstrap.success.color)),
          const DataCell(SizedBox.shrink()),
        ]),
        DataRow(cells: [
          const DataCell(Text('Voice Journaling')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Prompts & Templates')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Video, PDF Insertion')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Export as PNG, PDF')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('More Customization')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Date Counter. eg. Love Counter')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Relax Sounds')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
        DataRow(cells: [
          const DataCell(Text('Yearly Vision Board')),
          const DataCell(SizedBox.shrink()),
          DataCell(Icon(Icons.lock, color: ColorScheme.of(context).bootstrap.warning.color)),
        ]),
      ],
    );
  }
}
