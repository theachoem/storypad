import 'package:easy_localization/easy_localization.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart' show MdiIcons;
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/app_store_opener_service.dart' show AppStoreOpenerService;
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/views/community/local_widgets/community_card.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/routes/base_route.dart';

import 'community_view_model.dart';

part 'community_content.dart';

class CommunityRoute extends BaseRoute {
  CommunityRoute();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => CommunityView(params: this);
}

class CommunityView extends StatelessWidget {
  const CommunityView({
    super.key,
    required this.params,
  });

  final CommunityRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<CommunityViewModel>(
      create: (context) => CommunityViewModel(params: params),
      builder: (context, viewModel, child) {
        return _CommunityContent(viewModel);
      },
    );
  }
}
