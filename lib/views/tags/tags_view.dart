import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/routes/base_route.dart';

import 'tags_view_model.dart';

part 'tags_content.dart';

class TagsRoute extends BaseRoute {
  final bool storyViewOnly;

  TagsRoute({
    this.storyViewOnly = false,
  });

  @override
  Widget buildPage(BuildContext context) => TagsView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class TagsView extends StatelessWidget {
  const TagsView({
    super.key,
    required this.params,
  });

  final TagsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<TagsViewModel>(
      create: (context) => TagsViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _TagsContent(viewModel);
      },
    );
  }
}
