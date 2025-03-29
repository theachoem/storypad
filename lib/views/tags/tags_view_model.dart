import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'tags_view.dart';

class TagsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TagsRoute params;

  TagsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    context.read<TagsProvider>().reload();
  }
}
