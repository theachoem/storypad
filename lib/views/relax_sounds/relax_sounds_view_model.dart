import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'relax_sounds_view.dart';

class RelaxSoundsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final RelaxSoundsRoute params;

  RelaxSoundsViewModel({
    required this.params,
  });
}
