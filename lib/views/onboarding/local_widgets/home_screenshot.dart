import 'package:flutter/material.dart';
import 'package:storypad/gen/assets.gen.dart';

class HomeScreenshot extends StatelessWidget {
  const HomeScreenshot({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = ColorScheme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: "onboarding-home",
      child: Container(
        width: 300,
        height: 360,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
            left: BorderSide(color: Theme.of(context).dividerColor),
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
          image: DecorationImage(
            image: (isDarkMode ? Assets.images.onboarding.darkHome300x360 : Assets.images.onboarding.lightHome300x360)
                .provider(),
          ),
        ),
        child: child,
      ),
    );
  }
}
