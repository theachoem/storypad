import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/views/stories/helpers/base_story_view_model.dart';
import 'package:storypad/widgets/sp_icons.dart';

class ManagePagesButton extends StatelessWidget {
  const ManagePagesButton({
    super.key,
    required this.viewModel,
  });

  final BaseStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "button.manage_pages",
      child: IconButton(
        tooltip: tr("button.manage_pages"),
        icon: Icon(
          viewModel.pagesManager.managingPage ? SpIcons.managingPage : SpIcons.managingPageOff,
          color: viewModel.pagesManager.managingPage ? ColorScheme.of(context).tertiary : null,
        ),
        onPressed: () => viewModel.pagesManager.toggleManagingPage(),
      ),
    );
  }
}
