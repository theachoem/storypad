part of 'relax_sounds_view.dart';

class _RelaxSoundsContent extends StatelessWidget {
  const _RelaxSoundsContent(this.viewModel);

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            extendBody: true,
            appBar: AppBar(
              title: Text(tr('paywall_features.relax_sounds.title')),
              automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
              actions: [
                if (CupertinoSheetRoute.hasParentSheet(context))
                  CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: tr('general.sounds')),
                  Tab(child: Text(tr('general.sound_mixes'))),
                ],
              ),
            ),
            bottomNavigationBar: SpFloatingRelaxSoundsTile(
              onSaveMix: (context) async {
                viewModel.saveMix(context);
              },
            ),
            body: TabBarView(
              children: [
                _SoundsTab(viewModel: viewModel),
                _MixesTab(viewModel: viewModel),
              ],
            ),
          );
        },
      ),
    );
  }
}
