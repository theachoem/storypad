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
              title: Text(tr('add_ons.relax_sounds.title')),
              backgroundColor: ColorScheme.of(context).surface,
              automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
              actions: [
                if (CupertinoSheetRoute.hasParentSheet(context))
                  CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
              ],
              bottom: TabBar(
                onTap: (index) {
                  if (index == 1 && !context.read<InAppPurchaseProvider>().relaxSound) {
                    DefaultTabController.of(context).animateTo(0);
                    AddOnsRoute.pushAndNavigateTo(
                      product: AppProduct.relax_sounds,
                      context: context,
                      fullscreenDialog: true,
                    );
                  }
                },
                tabs: [
                  Tab(text: tr('general.sounds')),
                  Tab(
                    child: Consumer<InAppPurchaseProvider>(
                      builder: (context, iapProvider, child) {
                        return Text.rich(
                          TextSpan(
                            text: "${tr('general.sound_mixes')} ",
                            children: [
                              if (!iapProvider.relaxSound)
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    SpIcons.lock,
                                    size: 16.0,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
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
