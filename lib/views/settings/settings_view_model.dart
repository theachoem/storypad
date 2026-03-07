import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'settings_view.dart';

class SettingsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final SettingsRoute params;

  SettingsViewModel({
    required this.params,
  });
}
