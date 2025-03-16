part of 'theme_view.dart';

class _ThemeContent extends StatelessWidget {
  const _ThemeContent(this.viewModel);

  final ThemeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.theme.title")),
        actions: [
          SpPopupMenuButton(
            items: (context) {
              return [
                SpPopMenuItem(
                  leadingIconData: Icons.restart_alt_outlined,
                  title: tr("button.reset"),
                  onPressed: () {
                    context.read<ThemeProvider>().reset();
                  },
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                tooltip: tr("button.more_options"),
                icon: Icon(Icons.more_vert),
                onPressed: callback,
              );
            },
          )
        ],
      ),
      body: ListView(
        children: [
          ThemeModeTile.globalTheme(),
          ColorSeedTile(),
          Divider(),
          FontFamilyTile.globalTheme(),
          FontWeightTile.globalTheme(),
        ],
      ),
    );
  }
}
