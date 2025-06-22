part of 'throwback_view.dart';

class _ThrowbackContent extends StatelessWidget {
  const _ThrowbackContent(this.viewModel);

  final ThrowbackViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: buildAskUserToResponseBottomNav(context),
      floatingActionButton: FloatingActionButton(
        child: const Icon(SpIcons.newStory),
        onPressed: () => viewModel.goToNewPage(context),
      ),
      body: SpStoryList.withQuery(
        key: ValueKey(viewModel.editedKey),
        disableMultiEdit: true,
        filter: viewModel.filter,
      ),
    );
  }

  Widget buildAskUserToResponseBottomNav(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0)
              .add(MediaQuery.of(context).padding.copyWith(top: 0)),
          width: double.infinity,
          child: Row(
            spacing: 8.0,
            children: [
              const Icon(SpIcons.question),
              Expanded(
                child: Text(
                  tr('page.throwback.question'),
                  style: TextTheme.of(context).bodyMedium,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          text: "${tr('general.throwback')} ",
          style: TextTheme.of(context).titleLarge,
          children: [
            const WidgetSpan(
              child: Icon(Icons.history_outlined),
              alignment: PlaceholderAlignment.middle,
            ),
          ],
        ),
      ),
    );
  }
}
