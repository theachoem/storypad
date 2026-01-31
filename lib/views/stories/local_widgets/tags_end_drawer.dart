import 'package:flutter/material.dart';
import 'package:storypad/views/root/root_view.dart';
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
    return MediaQuery(
      // For end drawer, we don't use modifed padding by root content, we want original screen padding instead
      // because end drawer is on top of content.
      data: MediaQuery.of(RootView.rootContext ?? context),
      child: Drawer(
        child: Theme(
          data: Theme.of(context).copyWith(scaffoldBackgroundColor: Theme.of(context).colorScheme.surface),
          child: SpNestedNavigation(
            initialScreen: TagsView(
              params: TagsRoute(
                storyViewOnly: true,
                initialSelectedTags: initialTags,
                onToggleTags: onUpdated,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
