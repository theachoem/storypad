import 'package:flutter/cupertino.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/packages/sticky_header/sticky_header.dart';

import 'fonts_view_model.dart';

part 'fonts_content.dart';

class FontsRoute extends BaseRoute {
  const FontsRoute({
    required this.currentFontFamily,
    required this.currentFontWeight,
    required this.onChanged,
  });

  final String currentFontFamily;
  final FontWeight currentFontWeight;
  final void Function(String fontFamily) onChanged;

  @override
  Widget buildPage(BuildContext context) => FontsView(params: this);
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
        return Theme(
          data: AppTheme.getTheme(
            colorScheme: ColorScheme.of(context),
            fontFamily: viewModel.currentFontFamily,
            fontWeight: viewModel.currentFontWeight,
          ).copyWith(
            appBarTheme: AppBarTheme.of(context),
            scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: _FontsContent(viewModel),
        );
      },
    );
  }
}
