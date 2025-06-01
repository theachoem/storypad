import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

import 'show_template_view_model.dart';

part 'show_template_content.dart';

class ShowTemplateRoute extends BaseRoute {
  const ShowTemplateRoute({
    required this.template,
  });

  final TemplateDbModel template;

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => ShowTemplateView(params: this);
}

class ShowTemplateView extends StatelessWidget {
  const ShowTemplateView({
    super.key,
    required this.params,
  });

  final ShowTemplateRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowTemplateViewModel>(
      create: (context) => ShowTemplateViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowTemplateContent(viewModel);
      },
    );
  }
}
