import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpRewardSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget<String>(
      initialValue: '',
      builder: (context, notifier) {
        return Consumer<InAppPurchaseProvider>(builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitle(context),
                const SizedBox(height: 8),
                buildBody(),
                const SizedBox(height: 16),
                if (provider.rewardExpiredAt != null) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    trailing: IconButton(
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(SpIcons.clear),
                      onPressed: () => provider.clearReward(context),
                    ),
                    title: Text(tr('list_tile.unlock_your_rewards.applied_title')),
                    subtitle: Text(tr(
                      'general.expired_on',
                      namedArgs: {'EXP_DATE': DateFormatHelper.yMEd(provider.rewardExpiredAt!, context.locale)},
                    )),
                  ),
                ] else ...[
                  TextFormField(
                    initialValue: notifier.value,
                    onChanged: (value) => notifier.value = value.trim(),
                    decoration: InputDecoration(
                      hintText: tr('general.reward_code'),
                      prefixIcon: const Icon(SpIcons.gift),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildAdaptiveSubmitButton(context, notifier),
                ],
                buildBottomPadding(bottomPadding),
              ],
            ),
          );
        });
      },
    );
  }

  SpMarkdownBody buildBody() {
    return const SpMarkdownBody(
      body: '''
Share your story/diary on any social media in any format: text, photo, or video with the #storypad hashtag and get add-ons as a thank-you for sharing & inspiring others.

- **1 post** → 1 week free add-on
- **10+ upvotes/likes** → 1 month free add-on
- **100+ upvotes/likes** → Lifetime add-on unlock!

> After posting, message your link to [u/storypadapp](https://www.reddit.com/user/storypadapp) or [@StoryPadApp](https://x.com/StoryPadApp), and we'll send you a reward code.

> Help us grow the StoryPad community while we continue building daily tools for you. Thank you for being part of it! ✌️
      ''',
    );
  }

  RichText buildTitle(BuildContext context) {
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        text: "🌿 Post on social media & get free add-ons",
        style: Theme.of(context).textTheme.titleLarge,
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
  }

  Widget buildAdaptiveSubmitButton(BuildContext context, ValueNotifier<String> notifier) {
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, text, _) {
          if (kIsCupertino) {
            return CupertinoButton.filled(
              disabledColor: Theme.of(context).disabledColor,
              sizeStyle: CupertinoButtonSize.medium,
              onPressed: text.isNotEmpty == true
                  ? () async {
                      bool success = await context.read<InAppPurchaseProvider>().applyReward(context, text);
                      if (context.mounted && success) Navigator.maybePop(context);
                    }
                  : null,
              child: Text(tr('button.unlock')),
            );
          } else {
            return FilledButton.icon(
              label: Text(tr('button.unlock')),
              onPressed: text.isNotEmpty == true
                  ? () async {
                      bool success = await context.read<InAppPurchaseProvider>().applyReward(context, text);
                      if (context.mounted && success) Navigator.maybePop(context);
                    }
                  : null,
            );
          }
        },
      ),
    );
  }
}
