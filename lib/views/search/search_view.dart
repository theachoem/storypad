import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/widgets/story_list/story_list.dart';

import 'search_view_model.dart';

part 'search_adaptive.dart';

class SearchRoute extends BaseRoute {
  SearchRoute();

  @override
  Widget buildPage(BuildContext context) => SearchView(params: this);

  @override
  bool get nestedRoute => true;
}

class SearchView extends StatelessWidget {
  const SearchView({
    super.key,
    required this.params,
  });

  final SearchRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SearchViewModel>(
      create: (context) => SearchViewModel(params: params),
      builder: (context, viewModel, child) {
        return _SearchAdaptive(viewModel);
      },
    );
  }
}
