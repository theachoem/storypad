import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/views/templates/local_widgets/template_tag_labels.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';

import 'templates_view_model.dart';

part 'templates_content.dart';
part 'local_widgets/template_tile.dart';
part 'local_widgets/empty_body.dart';

class TemplatesRoute extends BaseRoute {
  const TemplatesRoute({
    this.initialYear,
    this.initialMonth,
    this.initialDay,
  });

  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;

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
