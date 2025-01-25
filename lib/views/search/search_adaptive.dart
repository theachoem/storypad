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
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "eg. My home",
            border: InputBorder.none,
          ),
          onChanged: (value) => viewModel.search(value),
          onSubmitted: (value) => viewModel.search(value),
        ),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: viewModel.queryNotifier,
        builder: (context, query, child) {
          return StoryList.withQuery(
            query: query,
            types: const [
              PathType.docs,
              PathType.archives,
            ],
          );
        },
      ),
    );
  }
}
