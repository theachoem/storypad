part of 'show_add_on_view.dart';

class _ShowAddOnContent extends StatelessWidget {
  const _ShowAddOnContent(this.viewModel);

  final ShowAddOnViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
      body: ListView(
        children: [
          buildContents(context, iapProvider),
          _DemoImages(demoImageUrls: viewModel.demoImageUrls, context: context),
          const SizedBox(height: 24.0),
          buildFAQTitle(context),
          const SizedBox(height: 8.0),
          ...buildFAQs(context),
        ],
      ),
    );
  }

  List<Widget> buildFAQs(BuildContext context) {
    return [
      ExpansionTile(
        title: Text(
          '1. Is it a lifetime purchase?',
          style: TextTheme.of(context).titleSmall,
        ),
        minTileHeight: 4.0,
        childrenPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        expandedAlignment: Alignment.centerLeft,
        children: [
          const Text(
            "Yes! When you buy this add-on, it's yours forever. No extra fees or subscriptions. Just one-time payment.",
          ),
        ],
      ),
      ExpansionTile(
        title: Text(
          '2. Will my purchase work on all my devices?',
          style: TextTheme.of(context).titleSmall,
        ),
        minTileHeight: 4.0,
        childrenPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        expandedAlignment: Alignment.centerLeft,
        children: [
          const Text(
            "Absolutely. Once you buy it, you can use the add-on on all your devices where you sign in with the same account, whether it's your phone, tablet, iPad.",
          ),
        ],
      ),
      ExpansionTile(
        title: Text(
          '3. Do I need to connect with Google Drive to purchase?',
          style: TextTheme.of(context).titleSmall,
        ),
        minTileHeight: 4.0,
        childrenPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        expandedAlignment: Alignment.centerLeft,
        children: [
          const Text(
            "Yes, you need to connect with Google Drive. This helps us restore your purchases later. We don't keep your email, only a secure ID.",
          ),
          Consumer<BackupProvider>(
            builder: (context, provider, child) {
              return Visibility(
                visible: !provider.isSignedIn,
                child: Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  child: OutlinedButton(
                    onPressed: () => provider.signIn(context),
                    child: const Text('Sign In'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget buildFAQTitle(BuildContext context) {
    Widget child = RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        text: 'FAQ',
        style: TextTheme.of(
          context,
        ).titleSmall?.copyWith(fontWeight: AppTheme.getThemeFontWeight(context, FontWeight.bold)),
        children: [
          if (context.locale.languageCode != 'en')
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.only(left: 6.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: ColorScheme.of(context).readOnly.surface2,
                ),
                child: Text(
                  'EN',
                  style: TextTheme.of(context).labelMedium,
                ),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: child,
    );
  }

  Widget buildContents(BuildContext context, InAppPurchaseProvider iapProvider) {
    final actions = [
      if (iapProvider.isActive(viewModel.params.addOn.type.productIdentifier)) ...[
        Expanded(
          child: FilledButton(
            child: Text(tr('button.open')),
            onPressed: () => viewModel.params.addOn.onOpen(context),
          ),
        ),
      ] else ...[
        Expanded(
          child: FilledButton(
            onPressed: viewModel.params.addOn.displayPrice == null
                ? null
                : () => viewModel.purchase(context, viewModel.params.addOn.type.productIdentifier),
            child: Text(viewModel.params.addOn.displayPrice ?? tr('button.unlock')),
          ),
        ),
        if (viewModel.params.addOn.onTry != null)
          Expanded(
            child: OutlinedButton(
              onPressed: () => viewModel.params.addOn.onTry!(context),
              child: Text(tr('button.try')),
            ),
          ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: ColorFromDayService(context: context).get(viewModel.params.addOn.weekdayColor),
            foregroundColor: ColorScheme.of(context).onPrimary,
            child: Icon(viewModel.params.addOn.iconData),
          ),
          const SizedBox(height: 12.0),
          Text(
            viewModel.params.addOn.title,
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            viewModel.params.addOn.subtitle,
            style: TextTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Row(
            spacing: 8.0,
            children: actions,
          ),
        ],
      ),
    );
  }
}
