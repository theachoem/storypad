import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_story_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class StoryShareButton extends StatelessWidget {
  const StoryShareButton({
    super.key,
    required this.viewModel,
  });

  final BaseStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.canShare) return const SizedBox.shrink();

    return IconButton(
      color: Theme.of(context).appBarTheme.foregroundColor,
      tooltip: tr("button.share"),
      icon: const Icon(SpIcons.share),
      onPressed: () {
        SpShareStoryBottomSheet(
          story: viewModel.story!,
          draftContent: viewModel.draftContent!,
          pagesManager: viewModel.pagesManager,
        ).show(context: context);
      },
    );
  }
}
