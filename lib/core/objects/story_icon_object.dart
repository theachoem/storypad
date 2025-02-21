import 'package:flutter/material.dart' show IconData, Icons;

/// Default showing favorite icon in story tile, but users can change it based on their preferences.
/// The selected icon is stored in `story.preferences`.
class StoryIconObject {
  final IconData filledIcon;
  final IconData outlineIcon;
  final double scale;

  const StoryIconObject({
    required this.filledIcon,
    required this.outlineIcon,
    required this.scale,
  });

  static StoryIconObject get fallbackIcon => icons.values.first;
  static const Map<String, StoryIconObject> icons = {
    "favorite": StoryIconObject(
      filledIcon: Icons.favorite,
      outlineIcon: Icons.favorite_border,
      scale: 1.0,
    ),
    "bookmark": StoryIconObject(
      filledIcon: Icons.bookmark_rounded,
      outlineIcon: Icons.bookmark_outline_rounded,
      scale: 1.05,
    ),
    "star": StoryIconObject(
      filledIcon: Icons.star,
      outlineIcon: Icons.star_border,
      scale: 1.2,
    ),
  };
}
