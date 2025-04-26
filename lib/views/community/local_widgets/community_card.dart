import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/widgets/sp_card.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
  });

  Future<void> openCustomTab(BuildContext context) async {
    await UrlOpenerService.openInCustomTab(
      context,
      RemoteConfigService.communityUrl.get(),
      prefersDeepLink: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpCard.withLogo(
      title: tr('list_tile.join_x.title'),
      subtitle: tr('list_tile.join_x.message'),
      logo: Assets.images.xLogo500x500.provider(),
      onTap: () => openCustomTab(context),
    );
  }
}
