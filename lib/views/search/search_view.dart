import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/widgets/story_list/story_list.dart';

import 'search_view_model.dart';

part 'search_content.dart';

class SearchRoute extends BaseRoute {
  SearchRoute({
    required this.initialFilter,
  });

  final SearchFilterObject initialFilter;

  @override
  Widget buildPage(BuildContext context) => SearchView(params: this);

  @override
  bool get preferredNestedRoute => true;
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
        return _SearchContent(viewModel);
      },
    );
  }
}
