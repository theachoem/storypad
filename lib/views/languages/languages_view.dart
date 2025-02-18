import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/routes/base_route.dart';

import 'languages_view_model.dart';

part 'languages_content.dart';

class LanguagesRoute extends BaseRoute {
  LanguagesRoute();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => LanguagesView(params: this);
}

class LanguagesView extends StatelessWidget {
  const LanguagesView({
    super.key,
    required this.params,
  });

  final LanguagesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<LanguagesViewModel>(
      create: (context) => LanguagesViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _LanguagesContent(viewModel);
      },
    );
  }
}
