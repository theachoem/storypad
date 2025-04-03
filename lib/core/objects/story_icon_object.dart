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
      filledIcon: (context) => SpIcons.of(context).favoriteFilled,
      outlineIcon: (context) => SpIcons.of(context).favorite,
      scale: 1.0,
    ),
    "bookmark": StoryIconObject(
      filledIcon: (context) => SpIcons.of(context).bookmarkFilled,
      outlineIcon: (context) => SpIcons.of(context).bookmark,
      scale: 1.05,
    ),
    "star": StoryIconObject(
      filledIcon: (context) => SpIcons.of(context).starFilled,
      outlineIcon: (context) => SpIcons.of(context).star,
      scale: 1.2,
    ),
  };
}
