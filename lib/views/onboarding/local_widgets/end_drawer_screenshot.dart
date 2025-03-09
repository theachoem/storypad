import 'package:flutter/material.dart';
import 'package:storypad/gen/assets.gen.dart';

enum EndDrawerScreenshotState {
  noSignedIn,
  signedIn,
  syning,
  synced,
}

class EndDrawerScreenshot extends StatelessWidget {
  const EndDrawerScreenshot({
    super.key,
    required this.state,
  });

  final EndDrawerScreenshotState state;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = ColorScheme.of(context).brightness == Brightness.dark;
    AssetGenImage imageGen;

    switch (state) {
      case EndDrawerScreenshotState.noSignedIn:
        imageGen = isDarkMode
            ? Assets.images.onboarding.darkDrawerNotSignedIn221x510
            : Assets.images.onboarding.lightDrawerNotSignedIn221x510;
        break;
      case EndDrawerScreenshotState.signedIn:
        imageGen = isDarkMode
            ? Assets.images.onboarding.darkDrawerSignedIn221x510
            : Assets.images.onboarding.lightDrawerSignedIn221x510;
        break;
      case EndDrawerScreenshotState.syning:
        imageGen = isDarkMode
            ? Assets.images.onboarding.darkDrawerSyning221x510
            : Assets.images.onboarding.lightDrawerSyning221x510;
        break;
      case EndDrawerScreenshotState.synced:
        imageGen = isDarkMode
            ? Assets.images.onboarding.darkDrawerSynced221x510
            : Assets.images.onboarding.lightDrawerSynced221x510;
        break;
    }

    return imageGen.image(width: 221, height: 510, alignment: Alignment.topCenter);
  }
}
