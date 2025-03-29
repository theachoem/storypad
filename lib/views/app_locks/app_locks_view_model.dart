import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'app_locks_view.dart';

class AppLocksViewModel extends ChangeNotifier with DisposeAwareMixin {
  final AppLocksRoute params;

  AppLocksViewModel({
    required this.params,
  });
}
