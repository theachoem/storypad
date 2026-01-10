import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'new_year_view.dart';

class NewYearViewModel extends ChangeNotifier with DisposeAwareMixin {
  final NewYearRoute params;

  NewYearViewModel({
    required this.params,
  });
}
