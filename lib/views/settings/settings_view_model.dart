import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/app_logo_service.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'settings_view.dart';

class SettingsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final SettingsRoute params;

  SettingsViewModel({
    required this.params,
  });

  void setAppLogo(AppLogo logo) async {
    await AppLogoService().set(logo);
    notifyListeners();
  }
}
