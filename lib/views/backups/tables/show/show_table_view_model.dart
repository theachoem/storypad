import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'show_table_view.dart';

class ShowTableViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowTableRoute params;

  ShowTableViewModel({
    required this.params,
  });
}
