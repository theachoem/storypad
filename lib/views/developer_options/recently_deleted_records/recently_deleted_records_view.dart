import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

import 'recently_deleted_records_view_model.dart';

part 'recently_deleted_records_content.dart';

class RecentlyDeletedRecordsRoute extends BaseRoute {
  const RecentlyDeletedRecordsRoute();

  @override
  Widget buildPage(BuildContext context) => RecentlyDeletedRecordsView(params: this);
}

class RecentlyDeletedRecordsView extends StatelessWidget {
  const RecentlyDeletedRecordsView({
    super.key,
    required this.params,
  });

  final RecentlyDeletedRecordsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RecentlyDeletedRecordsViewModel>(
      create: (context) => RecentlyDeletedRecordsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _RecentlyDeletedRecordsContent(viewModel);
      },
    );
  }
}
