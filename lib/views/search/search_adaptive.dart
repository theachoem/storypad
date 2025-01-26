part of 'search_view.dart';

class _SearchAdaptive extends StatelessWidget {
  const _SearchAdaptive(this.viewModel);

  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          textInputAction: TextInputAction.search,
          style: Theme.of(context).appBarTheme.titleTextStyle,
          keyboardType: TextInputType.text,
          autofocus: false,
          decoration: InputDecoration(
            hintText: "eg. My home",
            border: InputBorder.none,
          ),
          onChanged: (value) => viewModel.search(value),
          onSubmitted: (value) => viewModel.search(value),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: viewModel.queryNotifier,
        builder: (context, query, child) {
          return StoryList.withQuery(
            query: query,
            filter: viewModel.filter,
          );
        },
      ),
    );
  }
}
