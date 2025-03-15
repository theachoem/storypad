import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'new_year_view_model.dart';

part 'new_year_content.dart';

class NewYearRoute extends BaseRoute {
  NewYearRoute({
    required this.years,
  });

  Map<int, int>? years;

  @override
  Widget buildPage(BuildContext context) => NewYearView(params: this);
}

class NewYearView extends StatelessWidget {
  const NewYearView({
    super.key,
    required this.params,
  });

  final NewYearRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<NewYearViewModel>(
      create: (context) => NewYearViewModel(params: params),
      builder: (context, viewModel, child) {
        return _NewYearContent(viewModel);
      },
    );
  }
}
