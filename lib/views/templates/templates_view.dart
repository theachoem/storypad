import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/templates/local_widgets/gallery_tab.dart';
import 'package:storypad/views/templates/local_widgets/templates_tab.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'templates_view_model.dart';

part 'templates_content.dart';

class TemplatesRoute extends BaseRoute {
  const TemplatesRoute({
    this.initialYear,
    this.initialMonth,
    this.initialDay,
    this.viewingArchives = false,
  });

  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;
  final bool viewingArchives;

  @override
  Widget buildPage(BuildContext context) => TemplatesView(params: this);
}

class TemplatesView extends StatelessWidget {
  const TemplatesView({
    super.key,
    required this.params,
  });

  final TemplatesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<TemplatesViewModel>(
      create: (context) => TemplatesViewModel(params: params),
      builder: (context, viewModel, child) {
        return _TemplatesContent(viewModel);
      },
    );
  }
}
