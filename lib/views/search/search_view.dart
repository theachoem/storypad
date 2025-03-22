import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'search_view_model.dart';

part 'search_content.dart';

class SearchRoute extends BaseRoute {
  SearchRoute({
    required this.initialYear,
  });

  final int? initialYear;

  @override
  Widget buildPage(BuildContext context) => SearchView(params: this);
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
