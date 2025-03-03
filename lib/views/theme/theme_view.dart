import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/views/theme/local_widgets/color_seed_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_family_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/views/theme/local_widgets/theme_mode_tile.dart';

import 'theme_view_model.dart';

part 'theme_content.dart';

class ThemeRoute extends BaseRoute {
  ThemeRoute();

  @override
  Widget buildPage(BuildContext context) => ThemeView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class ThemeView extends StatelessWidget {
  const ThemeView({
    super.key,
    required this.params,
  });

  final ThemeRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ThemeViewModel>(
      create: (context) => ThemeViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ThemeContent(viewModel);
      },
    );
  }
}
