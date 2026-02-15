import 'package:flutter/services.dart';
import 'package:storypad/core/storages/base_object_storages/enum_storage.dart';
import 'package:storypad/gen/assets.gen.dart';

enum AppLogo {
  storypad_1_0(logoName: 'storypad_logo_1_0'),
  storypad_2_0(logoName: 'storypad_logo_2_0')
  ;

  final String logoName;

  const AppLogo({
    required this.logoName,
  });

  AssetGenImage get asset {
    switch (this) {
      case .storypad_1_0:
        return Assets.logos.storypadLogo10.assets.storypadLogo10;
      case .storypad_2_0:
        return Assets.logos.storypadLogo20.assets.storypadLogo20;
    }
  }
}

class _AppLogoStorage extends EnumStorage<AppLogo> {
  @override
  List<AppLogo> get values => AppLogo.values;
}

class AppLogoService {
  static const _channel = MethodChannel('app_logo');

  Future<AppLogo> getCurrent() async {
    return await _AppLogoStorage().readEnum() ?? AppLogo.storypad_1_0;
  }

  Future<void> set(AppLogo logo) async {
    await _AppLogoStorage().writeEnum(logo);

    // Pass configuration from Dart to keep native code lightweight
    await _channel.invokeMethod('setAlternateIconName', {
      'logoName': logo.logoName,
    });
  }

  Future<void> reset() async {
    await _AppLogoStorage().remove();

    await _channel.invokeMethod('setAlternateIconName', {
      'logoName': AppLogo.storypad_1_0.logoName, // default
    });
  }
}
