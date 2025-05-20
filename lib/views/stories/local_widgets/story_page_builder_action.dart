part of 'story_pages_builder.dart';

class StoryPageBuilderAction {
  final void Function() onAddPage;
  final void Function(int oldIndex, int newIndex) onSwapPages;
  final void Function(StoryPageObject page) onDelete;

  final void Function(int pageIndex, StoryPageObject page, bool titleFocused, bool bodyFocused) onFocusChange;
  final bool canDeletePage;

  StoryPageBuilderAction({
    required this.onAddPage,
    required this.onSwapPages,
    required this.onDelete,
    required this.onFocusChange,
    required this.canDeletePage,
  });
}
