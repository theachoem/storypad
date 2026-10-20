import 'package:flutter/widgets.dart';
import 'render_text_selection_highlight.dart';

/// Paints [selection] beneath [child], a text block whose component is [componentKey]'s (a `TextComponent`, or one
/// wrapping one, as a paragraph, list item or task does).
class TextSelectionHighlight extends SingleChildRenderObjectWidget {
  const TextSelectionHighlight({
    super.key,
    required this.componentKey,
    required this.selection,
    required this.color,
    required this.highlightWhenEmpty,
    required Widget super.child,
  });

  final GlobalKey componentKey;
  final TextSelection? selection;
  final Color color;

  /// Whether an empty block shows a highlight (it's within an expanded selection).
  final bool highlightWhenEmpty;

  @override
  RenderTextSelectionHighlight createRenderObject(BuildContext context) => RenderTextSelectionHighlight(
    componentKey: componentKey,
    selection: selection,
    color: color,
    highlightWhenEmpty: highlightWhenEmpty,
  );

  @override
  void updateRenderObject(BuildContext context, RenderTextSelectionHighlight renderObject) {
    renderObject
      ..componentKey = componentKey
      ..selection = selection
      ..color = color
      ..highlightWhenEmpty = highlightWhenEmpty;
  }
}
