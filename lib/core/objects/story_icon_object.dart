import 'package:flutter/material.dart' show BuildContext, IconData;
import 'package:storypad/widgets/sp_icons.dart';

/// Default showing favorite icon in story tile, but users can change it based on their preferences.
/// The selected icon is stored in `story.preferences`.
class StoryIconObject {
  final IconData Function(BuildContext context) filledIcon;
  final IconData Function(BuildContext context) outlineIcon;
  final double scale;

  const StoryIconObject({
    required this.filledIcon,
    required this.outlineIcon,
    required this.scale,
  });

  static StoryIconObject get fallbackIcon => icons.values.first;
  static Map<String, StoryIconObject> icons = {
    "favorite": StoryIconObject(
      filledIcon: (context) => SpIcons.favoriteFilled,
      outlineIcon: (context) => SpIcons.favorite,
      scale: 1.0,
    ),
    "bookmark": StoryIconObject(
      filledIcon: (context) => SpIcons.bookmarkFilled,
      outlineIcon: (context) => SpIcons.bookmark,
      scale: 1.05,
    ),
    "star": StoryIconObject(
      filledIcon: (context) => SpIcons.starFilled,
      outlineIcon: (context) => SpIcons.star,
      scale: 1.2,
    ),
  };
}
