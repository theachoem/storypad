part of 'home_years_view.dart';

class _HomeYearsContent extends StatelessWidget {
  const _HomeYearsContent(this.viewModel);

  final HomeYearsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: tr("page.add_year.title"),
            icon: const Icon(Icons.add),
            onPressed: () async => viewModel.addYear(context),
          ),
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (viewModel.years == null) return const Center(child: CircularProgressIndicator.adaptive());

    return ListView(
      children: buildYearsTiles(),
    );
  }

  List<Widget> buildYearsTiles() {
    return viewModel.years!.entries.map((entry) {
      bool selected = viewModel.params.viewModel.year == entry.key;
      return SpSingleStateWidget.listen(
        initialValue: false,
        builder: (context, loading, loadingNotifier) {
          return Stack(
            children: [
              ListTile(
                onTap: () async {
                  loadingNotifier.value = true;
                  await viewModel.params.viewModel.changeYear(entry.key);
                  loadingNotifier.value = false;
                },
                selected: selected,
                title: Text(entry.key.toString()),
                subtitle: Text(plural("plural.story", entry.value)),
                trailing: Visibility(visible: selected, child: const Icon(Icons.check)),
              ),
              AnimatedContainer(
                duration: Durations.long4,
                width: double.infinity,
                height: loading ? 4.0 : 0,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(),
                child: Wrap(
                  children: [LinearProgressIndicator()],
                ),
              ),
            ],
          );
        },
      );
    }).toList();
  }
}
