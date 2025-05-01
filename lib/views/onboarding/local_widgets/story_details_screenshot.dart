import 'package:flutter/material.dart';
import 'package:storypad/gen/assets.gen.dart';

class StoryDetailsScreenshot extends StatelessWidget {
  const StoryDetailsScreenshot({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = ColorScheme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300,
      height: 360,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          left: BorderSide(color: Theme.of(context).dividerColor),
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        image: DecorationImage(
          image: (isDarkMode
                  ? Assets.images.onboarding.darkStoryDetails300x360
                  : Assets.images.onboarding.lightStoryDetails300x360)
              .provider(),
        ),
      ),
    );
  }
}
