import 'raw_editor.dart';

/// How a [RawEditor] sizes and scrolls.
enum StoryEditorLayout {
  /// Fills its box and scrolls itself.
  scrolling,

  /// A box sized to its content, placed inside another scroll view -- e.g. in a `Column` in a
  /// `SingleChildScrollView`. That scroll view scrolls the editor: dragging over the text scrolls
  /// it, and it follows the caret. (Without any scroll view around it, the editor still sizes to its content.)
  box,

  /// A sliver sized to its content, for placing several editors in one `CustomScrollView`. Has no reorder or
  /// right-click chrome (they need a box around the editor).
  sliver,
}
