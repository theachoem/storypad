import 'package:flutter/cupertino.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'discover_view_model.dart';

part 'discover_content.dart';

class DiscoverRoute extends BaseRoute {
  const DiscoverRoute({
    this.initialPage,
  });

  final DiscoverSegmentId? initialPage;

  @override
  Widget buildPage(BuildContext context) => DiscoverView(params: this);
}

class DiscoverView extends StatelessWidget {
  const DiscoverView({
    super.key,
    required this.params,
  });

  final DiscoverRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<DiscoverViewModel>(
      create: (context) => DiscoverViewModel(params: params),
      builder: (context, viewModel, child) {
        return _DiscoverContent(viewModel);
      },
    );
  }
}
