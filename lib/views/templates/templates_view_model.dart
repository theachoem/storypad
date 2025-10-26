import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'templates_view.dart';

class TemplatesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TemplatesRoute params;

  TemplatesViewModel({
    required this.params,
  });

  final ValueNotifier<List<IconButton>?> appBarActionsNotifier = ValueNotifier(null);

  @override
  void dispose() {
    appBarActionsNotifier.dispose();
    super.dispose();
  }
}
