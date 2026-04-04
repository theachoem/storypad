part of '../paywall_view.dart';

class _RestoreAndRedeemTexts extends StatelessWidget {
  const _RestoreAndRedeemTexts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 8.0,
        bottom: 16.0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children:
            [
              (
                tr('button.restore_purchase'),
                () => context.read<InAppPurchaseProvider>().restorePurchase(context),
              ),
              ("•", null),
              (
                tr('button.redeem_code'),
                () => context.read<InAppPurchaseProvider>().presentCodeRedemptionSheet(context),
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
    );
  }
}
