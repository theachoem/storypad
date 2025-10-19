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

    return ListView.separated(
      padding: const EdgeInsets.all(16.0).add(
        EdgeInsets.only(
          bottom: padding.bottom,
          left: padding.left,
          right: padding.right,
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemCount: viewModel.addOns!.length + 1,
      itemBuilder: (context, index) {
        if (index == viewModel.addOns!.length) {
          if (!kRedeemCodeEnabled || !kIAPEnabled) return const SizedBox.shrink();
          return buildRewardsCard();
        }

        final addOn = viewModel.addOns![index];
        return _AddOnCard(
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
        return ListTile(
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
          trailing: const Icon(SpIcons.keyboardRight),
          subtitle: provider.rewardExpiredAt != null
              ? Text(
                  tr(
                    'general.expired_on',
                    namedArgs: {'EXP_DATE': DateFormatHelper.yMEd(provider.rewardExpiredAt!, context.locale)},
                  ),
                )
              : null,
          onTap: () => SpRewardSheet().show(context: context),
        );
      },
    );
  }

  Widget buildBottomNavigation(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children:
            [
              (
                tr('general.term_of_use'),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
              ),
              (
                tr('general.privacy_policy'),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy'),
              ),
              (
                tr('button.restore_purchase'),
                () => context.read<InAppPurchaseProvider>().restorePurchase(context),
              ),
            ].map((link) {
              return SpTapEffect(
                onTap: link.$2,
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    link.$1,
                    style: TextTheme.of(context).bodyMedium?.copyWith(
                      color: ColorScheme.of(context).primary,
                      decoration: TextDecoration.underline,
                      decorationColor: ColorScheme.of(context).primary,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
