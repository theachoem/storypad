import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_tags_picker_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_templates_picker_sheet.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_capacity_badge.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'home_quick_actions_view_model.dart';

part 'home_quick_actions_content.dart';
part 'local_widgets/preview.dart';
part 'local_widgets/available_actions.dart';

class HomeQuickActionsRoute extends BaseRoute {
  const HomeQuickActionsRoute();

  @override
  String? get routeName => 'home_quick_actions';

  @override
  Widget buildPage(BuildContext context) => HomeQuickActionsView(params: this);
}

class HomeQuickActionsView extends StatelessWidget {
  const HomeQuickActionsView({
    super.key,
    required this.params,
  });

  final HomeQuickActionsRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeQuickActionsViewModel>(
      create: (context) => HomeQuickActionsViewModel(params: params, context: context),
      builder: (context, child) {
        return _HomeQuickActionsContent(Provider.of(context));
      },
    );
  }
}
