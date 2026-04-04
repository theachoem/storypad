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
                onTap: (index) {
                  if (index == 1 && !context.read<InAppPurchaseProvider>().isProUser) {
                    DefaultTabController.of(context).animateTo(0);
                    const PaywallRoute(initialFocus: .relax_sounds).push(context);
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
                              if (!iapProvider.isProUser)
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
              physics: context.read<InAppPurchaseProvider>().isProUser ? null : const NeverScrollableScrollPhysics(),
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
