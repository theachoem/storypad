part of 'relax_sounds_view.dart';

class _RelaxSoundsContent extends StatelessWidget {
  const _RelaxSoundsContent(this.viewModel);

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(tr('add_ons.relax_sounds.title')),
          backgroundColor: ColorScheme.of(context).surface,
          automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
          actions: [
            if (CupertinoSheetRoute.hasParentSheet(context))
              CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
          ],
          bottom: TabBar(tabs: [
            Tab(text: tr('general.sounds')),
            Tab(text: tr('general.sound_mixes')),
          ]),
        ),
        bottomNavigationBar: SpFloatingRelaxSoundsTile(
          onSaveMix: (context) async {
            DefaultTabController.maybeOf(context)?.animateTo(1);
            viewModel.saveMix(context);
          },
        ),
        body: TabBarView(
          children: [
            _SoundsTab(viewModel: viewModel),
            _MixesTab(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}
