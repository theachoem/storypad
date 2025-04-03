import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/views/theme/theme_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'languages_view_model.dart';

part 'languages_content.dart';

class LanguagesRoute extends BaseRoute {
  LanguagesRoute({
    this.showBetaBanner = true,
    this.showThemeFAB = false,
    this.fromOnboarding = false,
  });

  final bool showBetaBanner;
  final bool showThemeFAB;
  final bool fromOnboarding;

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
