import 'package:flutter/widgets.dart';
import 'package:storypad/core/types/page_layout_type.dart';

/// What embeds need from the story around their editor, which the embeds themselves (const, shared by every editor)
/// can't hold: the page layout (embeds size down in the grid layout) and every media path in the story (the media
/// viewer pages through all of them).
class SpEditorScope extends InheritedWidget {
  const SpEditorScope({
    super.key,
    required this.layoutType,
    required this.fetchAllMedia,
    required super.child,
  });

  final PageLayoutType? layoutType;
  final List<String> Function() fetchAllMedia;

  static SpEditorScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SpEditorScope>();

  @override
  bool updateShouldNotify(SpEditorScope oldWidget) => layoutType != oldWidget.layoutType;
}
