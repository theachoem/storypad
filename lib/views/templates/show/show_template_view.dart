import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_builder.dart';
import 'package:storypad/views/templates/local_widgets/template_tag_labels.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_story_preference_theme.dart';

import 'show_template_view_model.dart';

part 'show_template_content.dart';

class ShowTemplateRoute extends BaseRoute {
  ShowTemplateRoute({
    required this.template,
    this.initialYear,
    this.initialMonth,
    this.initialDay,
  });

  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;

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
        return SpStoryPreferenceTheme(
          preferences: viewModel.template.preferences,
          child: _ShowTemplateContent(viewModel),
        );
      },
    );
  }
}
