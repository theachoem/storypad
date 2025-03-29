import 'package:flutter/material.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class TagsEndDrawer extends StatelessWidget {
  const TagsEndDrawer({
    super.key,
    required this.initialTags,
    required this.onUpdated,
  });

  final List<int> initialTags;
  final Future<bool> Function(List<int> tags) onUpdated;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SpNestedNavigation(
        initialScreen: TagsView(
          params: TagsRoute(
            storyViewOnly: true,
            initialSelectedTags: initialTags,
            onToggleTags: onUpdated,
          ),
        ),
      ),
    );
  }
}
