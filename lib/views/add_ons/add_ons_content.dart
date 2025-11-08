part of 'add_ons_view.dart';

class _AddOnsContent extends StatelessWidget {
  const _AddOnsContent(this.viewModel);

  final AddOnsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.add_ons.title')),
        centerTitle: kIsCupertino,
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }

  Widget buildBody(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    if (viewModel.addOns == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final isMediumScreen = screenWidth > 600;

    int crossAxisCount = isLargeScreen ? 4 : (isMediumScreen ? 3 : 2);

    return AlignedGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12.0,
      crossAxisSpacing: 12.0,
      itemCount: viewModel.addOns!.length,
      padding: EdgeInsets.only(
        top: 16.0,
        bottom: padding.bottom + 16.0,
        left: padding.left + 16.0,
        right: padding.right + 16.0,
      ),
      itemBuilder: (context, index) {
        final addOn = viewModel.addOns![index];
        return _AddOnGridItem(
          addOn: addOn,
          onTap: () => ShowAddOnRoute(
            addOn: addOn,
            fullscreenDialog: viewModel.params.fullscreenDialog,
          ).push(context),
        );
      },
    );
  }

  Widget buildRewardsCard() {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).add(
            EdgeInsets.only(
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            ),
          ),
          child: ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            key: ValueKey(provider.rewardExpiredAt != null ? 'appied' : 'not_applied'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            leading: const SpGiftAnimatedIcon(),
            title: Text(
              provider.rewardExpiredAt != null
                  ? tr('list_tile.unlock_your_rewards.applied_title')
                  : tr('list_tile.unlock_your_rewards.unapplied_title'),
            ),
            trailing: const Icon(SpIcons.info, size: 20),
            subtitle: provider.rewardExpiredAt != null
                ? Text(
                    tr(
                      'general.expired_on',
                      namedArgs: {'EXP_DATE': DateFormatHelper.yMEd(provider.rewardExpiredAt!, context.locale)},
                    ),
                  )
                : null,
            onTap: () => SpRewardSheet().show(context: context),
          ),
        );
      },
    );
  }

  Widget buildBottomNavigation(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kIAPEnabled) buildRewardsCard(),
        Container(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 8.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children:
                [
                  (
                    (tr('general.term_of_use')),
                    () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
                  ),
                  ("•", null),
                  (
                    (tr('general.privacy_policy')),
                    () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy'),
                  ),
                  ("•", null),
                  (
                    tr('button.restore_purchase'),
                    () => context.read<InAppPurchaseProvider>().restorePurchase(context),
                  ),
                ].map((link) {
                  return SpTapEffect(
                    onTap: link.$2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
                      child: Text(
                        link.$1,
                        style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
