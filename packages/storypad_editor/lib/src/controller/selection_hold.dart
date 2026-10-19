part of 'story_editor_controller.dart';

/// A hold on the editor's selection, from [StoryEditorController.holdSelection]. Release it when the popup closes.
final class SelectionHold {
  SelectionHold._(this._controller);

  final StoryEditorController _controller;
  bool _released = false;

  /// Releases the hold. Safe to call more than once.
  void release() {
    if (_released) return;
    _released = true;
    _controller._release();
  }
}
