import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/services/app_store_opener_service.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SupportUsRoute extends BaseRoute {
  SupportUsRoute();

  @override
  String? get routeName => 'support_us';

  @override
  Widget buildPage(BuildContext context) => const SupportUsView();
}

class SupportUsView extends StatelessWidget {
  const SupportUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final productHuntUrl = RemoteConfigService.productHuntUrl.get();
    final alternativeToUrl = RemoteConfigService.alternativeToUrl.get();
    final sourceCodeUrl = RemoteConfigService.sourceCodeUrl.get();

    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 24.0,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0).add(
              EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
              ),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(tr('page.support_us.title'), style: Theme.of(context).textTheme.headlineSmall),
                Text(tr("page.support_us.message")),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          ListTile(
            leading: const Icon(SpIcons.star),
            title: Text(
              tr(
                'list_tile.rate_on_store.title',
                namedArgs: {'ARG_NAME': Platform.isAndroid ? 'Play Store' : 'App Store'},
              ),
            ),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () => AppStoreOpenerService.call(),
          ),
          if (productHuntUrl.trim().isNotEmpty) ...[
            ListTile(
              leading: Icon(MdiIcons.rocketLaunchOutline),
              title: Text(tr('list_tile.product_hunt.title', namedArgs: {'ARG_NAME': 'Product Hunt'})),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => UrlOpenerService.openInCustomTab(context, productHuntUrl),
            ),
          ],
          if (alternativeToUrl.trim().isNotEmpty) ...[
            ListTile(
              leading: const Icon(SpIcons.compare),
              title: Text(tr('list_tile.alternative_to.title', namedArgs: {'ARG_NAME': 'AlternativeTo'})),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => UrlOpenerService.openInCustomTab(context, alternativeToUrl),
            ),
          ],
          if (sourceCodeUrl.trim().isNotEmpty) ...[
            ListTile(
              leading: Icon(MdiIcons.github),
              title: Text(tr('list_tile.github_star.title', namedArgs: {'ARG_NAME': 'GitHub'})),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => UrlOpenerService.openInCustomTab(context, sourceCodeUrl),
            ),
          ],
        ],
      ),
    );
  }
}
