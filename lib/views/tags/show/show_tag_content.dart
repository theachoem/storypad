part of 'show_tag_view.dart';

class _ShowTagContent extends StatelessWidget {
  const _ShowTagContent(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitle(context),
        actions: [
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(Icons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      body: StoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: viewModel.filter,
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return SpTapEffect(
      onTap: () => viewModel.goToEditPage(context),
      child: RichText(
        text: TextSpan(
          text: "${viewModel.tag.title} ",
          style: TextTheme.of(context).titleLarge,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.edit_outlined,
                size: 20.0,
                color: ColorScheme.of(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
