import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/views/stories/local_widgets/story_end_drawer_button.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_builder.dart';
import 'package:storypad/views/stories/local_widgets/tags_end_drawer.dart';
import 'package:storypad/views/templates/local_widgets/template_tag_labels.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/pages_toolbar/sp_pages_toolbar.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_story_preference_theme.dart';

import 'edit_template_view_model.dart';

part 'edit_template_content.dart';
part 'local_widgets/done_button.dart';

class EditTemplateRoute extends BaseRoute {
  EditTemplateRoute({
    this.initialTemplate,
  });

  final TemplateDbModel? initialTemplate;

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => EditTemplateView(params: this);
}

class EditTemplateView extends StatelessWidget {
  const EditTemplateView({
    super.key,
    required this.params,
  });

  final EditTemplateRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<EditTemplateViewModel>(
      create: (context) => EditTemplateViewModel(params: params),
      builder: (context, viewModel, child) {
        return SpStoryPreferenceTheme(
          preferences: viewModel.template?.preferences,
          child: _EditTemplateContent(viewModel),
        );
      },
    );
  }
}
