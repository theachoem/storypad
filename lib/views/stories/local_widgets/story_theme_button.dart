import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_theme_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class StoryThemeButton extends StatelessWidget {
  const StoryThemeButton({
    super.key,
    required this.viewModel,
  });

  final BaseStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "page.theme.title",
      child: IconButton(
        tooltip: tr("page.theme.title"),
        icon: const Icon(SpIcons.moreVert),
        onPressed: () async {
          var nextAction = await SpStoryThemeBottomSheet(
            story: viewModel.story!,
            onThemeChanged: (preferences) => viewModel.changePreferences(preferences),
            draftContent: viewModel.draftContent,
            viewModel: viewModel,
          ).show(context: context);

          if (!context.mounted) return;
          if (nextAction is SpStoryThemeBottomSheetPopAction) {
            switch (nextAction) {
              case SpStoryThemeBottomSheetPopAction.backToStoryList:
                Navigator.maybePop(context);
                break;
            }
          }
        },
      ),
    );
  }
}
