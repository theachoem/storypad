part of 'theme_view.dart';

class _ThemeContent extends StatelessWidget {
  const _ThemeContent(this.viewModel);

  final ThemeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Theme"),
      ),
      body: ListView(
        children: const [
          ThemeModeTile(),
          ColorSeedTile(),
          Divider(),
          FontFamilyTile(),
          FontWeightTile(),
        ],
      ),
    );
  }
}
