import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'tags_view.dart';

class TagsViewModel extends BaseViewModel {
  final TagsRoute params;

  TagsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    context.read<TagsProvider>().reload();
  }
}
