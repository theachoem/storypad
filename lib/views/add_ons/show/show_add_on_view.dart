import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

import 'show_add_on_view_model.dart';

part 'show_add_on_content.dart';
part '../local_widgets/demo_images.dart';

class ShowAddOnRoute extends BaseRoute {
  const ShowAddOnRoute({
    required this.addOn,
  });

  final AddOnObject addOn;

  @override
  Widget buildPage(BuildContext context) => ShowAddOnView(params: this);
}

class ShowAddOnView extends StatelessWidget {
  const ShowAddOnView({
    super.key,
    required this.params,
  });

  final ShowAddOnRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowAddOnViewModel>(
      create: (context) => ShowAddOnViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowAddOnContent(viewModel);
      },
    );
  }
}
