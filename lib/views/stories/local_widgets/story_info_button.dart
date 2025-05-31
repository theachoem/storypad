import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_info_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class StoryInfoButton extends StatelessWidget {
  const StoryInfoButton({
    super.key,
    required this.viewModel,
  });

  final BaseStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "button.info",
      child: IconButton(
        tooltip: tr("button.info"),
        icon: const Icon(SpIcons.info),
        onPressed: viewModel.story == null
            ? null
            : () => SpStoryInfoSheet(
                  story: viewModel.story!,
                  persisted: viewModel.flowType == EditingFlowType.update,
                ).show(context: context),
      ),
    );
  }
}
