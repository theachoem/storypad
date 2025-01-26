part of 'archives_view.dart';

class _ArchivesAdaptive extends StatelessWidget {
  const _ArchivesAdaptive(this.viewModel);

  final ArchivesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SpPopupMenuButton(
          dyGetter: (dy) => dy + 48,
          dxGetter: (dx) => dx - 48.0,
          items: (context) {
            return [PathType.archives, PathType.bins].map((type) {
              return SpPopMenuItem(
                selected: type == viewModel.type,
                title: type.localized,
                onPressed: () {
                  viewModel.setType(type);
                },
              );
            }).toList();
          },
          builder: (open) {
            return SpTapEffect(
              onTap: open,
              child: RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(
                  style: TextTheme.of(context).titleLarge,
                  text: viewModel.type.localized,
                  children: const [
                    WidgetSpan(child: Icon(Icons.arrow_drop_down)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: StoryList.withQuery(
        viewOnly: true,
        filter: SearchFilterObject(
          years: {},
          types: {viewModel.type},
          tagId: null,
        ),
      ),
    );
  }
}
