import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/show/show_add_on_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'add_ons_view_model.dart';

part 'add_ons_content.dart';
part 'local_widgets/add_on_card.dart';

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
      create: (context) => AddOnsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _AddOnsContent(viewModel);
      },
    );
  }
}
