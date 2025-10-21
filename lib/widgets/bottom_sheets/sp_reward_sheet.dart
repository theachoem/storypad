import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';

class SpRewardSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitle(context),
              const SizedBox(height: 12.0),
              buildBody(context),
              const SizedBox(height: 16.0),
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
                  subtitle: Text(
                    tr(
                      'general.expired_on',
                      namedArgs: {'EXP_DATE': DateFormatHelper.yMEd(provider.rewardExpiredAt!, context.locale)},
                    ),
                  ),
                ),
              ] else ...[
                buildAdaptiveSubmitButton(context),
              ],
              buildBottomPadding(bottomPadding),
            ],
          ),
        );
      },
    );
  }

  Widget buildBody(BuildContext context) {
    const String body = '''
Help us grow the StoryPad community! 🌱
- [ ] Post about your StoryPad experience (text, photo, video, or screenshot).
- [ ] Tag #storypad or mention @storypadapp, or simply include the word StoryPad in your post on any platform.
- [x] Get **1 FREE add-on** as a thank-you gift! 🎁
''';

    const String additionalBody = '''
After posting, DM your link to [@StoryPadApp](https://x.com/StoryPadApp), and we'll send you a reward code.
''';

    return Visibility(
      visible: MediaQuery.of(context).viewInsets.bottom == 0, // keyboard closed
      child: SpFadeIn.fromBottom(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: ColorScheme.of(context).readOnly.surface2,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpMarkdownBody(body: body),
              SizedBox(height: 12.0),
              Divider(height: 1.0),
              SizedBox(height: 8.0),
              SpMarkdownBody(body: additionalBody),
            ],
          ),
        ),
      ),
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

  Widget buildAdaptiveSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (context) {
          if (kIsCupertino) {
            return CupertinoButton.filled(
              disabledColor: Theme.of(context).disabledColor,
              sizeStyle: CupertinoButtonSize.medium,
              child: Text(tr('button.unlock')),
              onPressed: () => context.read<InAppPurchaseProvider>().presentCodeRedemptionSheet(),
            );
          } else {
            return FilledButton.icon(
              label: Text(tr('button.unlock')),
              onPressed: () => context.read<InAppPurchaseProvider>().presentCodeRedemptionSheet(),
            );
          }
        },
      ),
    );
  }
}
