import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/routes/base_route.dart';

import 'tags_view_model.dart';

part 'tags_adaptive.dart';

class TagsRoute extends BaseRoute {
  final bool storyViewOnly;

  TagsRoute({
    this.storyViewOnly = false,
  });

  @override
  Widget buildPage(BuildContext context) => TagsView(params: this);

  @override
  bool get nestedRoute => true;
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
      create: (context) => TagsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _TagsAdaptive(viewModel);
      },
    );
  }
}
