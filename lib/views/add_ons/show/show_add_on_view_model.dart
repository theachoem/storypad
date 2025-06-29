import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'show_add_on_view.dart';

class ShowAddOnViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowAddOnRoute params;

  ShowAddOnViewModel({
    required this.params,
  });
}
