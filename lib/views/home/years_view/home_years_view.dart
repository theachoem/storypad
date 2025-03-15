import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'home_years_view_model.dart';

part 'home_years_content.dart';

class HomeYearsRoute extends BaseRoute {
  HomeYearsRoute({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget buildPage(BuildContext context) => HomeYearsView(params: this);
}

class HomeYearsView extends StatelessWidget {
  const HomeYearsView({
    super.key,
    required this.params,
  });

  final HomeYearsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<HomeYearsViewModel>(
      create: (context) => HomeYearsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _HomeYearsContent(viewModel);
      },
    );
  }
}
