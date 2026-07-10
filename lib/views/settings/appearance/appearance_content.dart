part of 'appearance_view.dart';

class _AppearanceContent extends StatelessWidget {
  const _AppearanceContent(this.viewModel);

  final AppearanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("general.customization")),
        actions: [
          SpPopupMenuButton(
            items: (context) {
              return [
                SpPopMenuItem(
                  leadingIconData: SpIcons.refresh,
                  title: tr("button.reset"),
                  onPressed: () => viewModel.reset(context),
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                tooltip: tr("button.more_options"),
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          for (int i = 0; i < viewModel.sections.length; i++) ...[
            if (i > 0) const Divider(),
            SpSectionTitle(title: viewModel.sections[i].title),
            for (final item in viewModel.sections[i].items) item.builder(context),
          ],
        ],
      ),
    );
  }
}
