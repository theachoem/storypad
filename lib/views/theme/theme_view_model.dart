import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'theme_view.dart';

class ThemeViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ThemeRoute params;

  ThemeViewModel({
    required this.params,
  });
}
