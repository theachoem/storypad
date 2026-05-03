import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/types/add_on_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_demo_images_sheet.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

import 'add_ons_view_model.dart';

part 'add_ons_content.dart';

class AddOnsRoute extends BaseRoute {
  const AddOnsRoute();

  @override
  Widget buildPage(BuildContext context) => AddOnsView(params: this);
}

class AddOnsView extends StatelessWidget {
  const AddOnsView({
    super.key,
    required this.params,
  });

  final AddOnsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<AddOnsViewModel>(
      create: (context) => AddOnsViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _AddOnsContent(viewModel);
      },
    );
  }
}
