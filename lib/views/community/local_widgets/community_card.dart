import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: [SpTapEffectType.scaleDown],
      onTap: () => UrlOpenerService.openInCustomTab(
        context,
        RemoteConfigService.communityUrl.get(),
        prefersDeepLink: true,
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Theme.of(context).colorScheme.tertiaryContainer,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 16,
              bottom: 16,
              child: SpFadeIn.bound(
                delay: Durations.medium1,
                child: Assets.images.redditLogo500x500.image(
                  height: 64,
                  width: 64,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              margin: EdgeInsets.only(right: 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('list_tile.join_reddit.title'),
                    style: TextTheme.of(context)
                        .titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    tr('list_tile.join_reddit.message'),
                    style: TextTheme.of(context).bodyMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                  ),
                  SizedBox(height: 12.0),
                ],
              ),
            ),
            Positioned(
              top: 16.0,
              right: 16.0,
              child: Icon(Icons.keyboard_arrow_right),
            ),
          ],
        ),
      ),
    );
  }
}
