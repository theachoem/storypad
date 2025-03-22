import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/widgets/story_list/sp_story_tile.dart';

class SpSpStoryListTimelineVerticleDivider extends StatelessWidget {
  const SpSpStoryListTimelineVerticleDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: AppTheme.getDirectionValue(
        context,
        null,
        MediaQuery.of(context).padding.left + 16.0 + SpStoryTile.monogramSize / 2,
      ),
      right: AppTheme.getDirectionValue(
        context,
        MediaQuery.of(context).padding.left + 16.0 + SpStoryTile.monogramSize / 2,
        null,
      ),
      child: const VerticalDivider(
        width: 1,
      ),
    );
  }
}
