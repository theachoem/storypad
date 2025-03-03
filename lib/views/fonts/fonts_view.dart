import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sticky_header/sticky_header.dart';

import 'fonts_view_model.dart';

part 'fonts_content.dart';

class FontsRoute extends BaseRoute {
  FontsRoute();

  @override
  Widget buildPage(BuildContext context) => FontsView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class FontsView extends StatelessWidget {
  const FontsView({
    super.key,
    required this.params,
  });

  final FontsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<FontsViewModel>(
      create: (context) => FontsViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _FontsContent(viewModel);
      },
    );
  }
}
