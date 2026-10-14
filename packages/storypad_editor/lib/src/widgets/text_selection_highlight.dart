import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

/// The width an empty line's highlight gets, as super_editor's (`TextLayoutEmptyHighlight`, and `TextSelectionPainter`
/// for an empty line within a selection).
const _emptyBlockHighlightWidth = 20.0;
const _emptyLineHighlightWidth = 5.0;

/// Paints text blocks' selection highlight in place of super_editor's, as native text (and Flutter's `TextField`) does:
/// each line's box exactly over its own height, a block's boxes in one fill.
///
/// super_editor's `TextSelectionPainter` (super_text_layout) grows each line's box 2px up and down
/// (`selectionHighlightBoxVerticalExpansion`) and fills the boxes one by one, so the lines of a wrapped paragraph, and
/// blocks that touch, overlap by 4px, and the see-through selection color darkens there. Its `TextComponent` gives no
/// way to change that: the block it builds is given a transparent selection color instead, and this paints beneath it,
/// at its text.
class TextSelectionHighlightComponentBuilder implements ComponentBuilder {
  const TextSelectionHighlightComponentBuilder(this.delegate);

  final ComponentBuilder delegate;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! TextComponentViewModel) {
      return delegate.createComponent(componentContext, componentViewModel);
    }

    final selection = componentViewModel.selection;
    final color = componentViewModel.selectionColor;
    final highlightWhenEmpty = componentViewModel.highlightWhenEmpty;
    final isSelected = selection != null || highlightWhenEmpty;
    // A copy: the layout compares the view models it's given to tell what changed.
    final viewModel = isSelected ? componentViewModel.copy() : componentViewModel;
    if (isSelected && viewModel is TextComponentViewModel) viewModel.selectionColor = const Color(0x00000000);

    final component = delegate.createComponent(componentContext, viewModel);
    if (component == null) return null;

    // Wrapping unselected blocks too keeps the tree the same shape as the selection comes and goes.
    return TextSelectionHighlight(
      componentKey: componentContext.componentKey,
      selection: selection,
      color: color,
      highlightWhenEmpty: highlightWhenEmpty,
      child: component,
    );
  }
}

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

class RenderTextSelectionHighlight extends RenderProxyBox {
  RenderTextSelectionHighlight({
    required GlobalKey componentKey,
    required TextSelection? selection,
    required Color color,
    required bool highlightWhenEmpty,
  }) : _componentKey = componentKey,
       _selection = selection,
       _color = color,
       _highlightWhenEmpty = highlightWhenEmpty;

  GlobalKey get componentKey => _componentKey;
  GlobalKey _componentKey;
  set componentKey(GlobalKey value) {
    if (value == _componentKey) return;
    _componentKey = value;
    markNeedsPaint();
  }

  TextSelection? get selection => _selection;
  TextSelection? _selection;
  set selection(TextSelection? value) {
    if (value == _selection) return;
    _selection = value;
    markNeedsPaint();
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  bool get highlightWhenEmpty => _highlightWhenEmpty;
  bool _highlightWhenEmpty;
  set highlightWhenEmpty(bool value) {
    if (value == _highlightWhenEmpty) return;
    _highlightWhenEmpty = value;
    markNeedsPaint();
  }

  /// The block's `TextComponent`: the component itself, or the first one inside it (past a list item's numeral, or a
  /// task's checkbox). Looked up at each paint, not kept: a rebuild can swap it for a new one, and only selected blocks
  /// look.
  TextComponentState? _findText() {
    final state = _componentKey.currentState;
    if (state is TextComponentState) return state;

    TextComponentState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is TextComponentState) {
        found = element.state as TextComponentState;
      } else {
        element.visitChildren(visit);
      }
    }

    _componentKey.currentContext?.visitChildElements(visit);
    return found;
  }

  /// The paragraph laying out [text]'s text: the first in its render tree (its highlight layer, beneath the text, has
  /// none). Read directly, as its `textLayout` is only for tests.
  static RenderParagraph? _paragraphOf(RenderObject text) {
    RenderParagraph? found;
    void visit(RenderObject child) {
      if (found != null) return;
      if (child is RenderParagraph) {
        found = child;
      } else {
        child.visitChildren(visit);
      }
    }

    text.visitChildren(visit);
    return found;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_selection != null || _highlightWhenEmpty) _paintHighlight(context.canvas, offset);
    super.paint(context, offset);
  }

  void _paintHighlight(Canvas canvas, Offset offset) {
    final text = _findText()?.context.findRenderObject();
    final paragraph = text == null ? null : _paragraphOf(text);
    if (paragraph == null || !paragraph.hasSize) return;

    final origin = offset + paragraph.localToGlobal(Offset.zero, ancestor: this);
    final path = Path();
    if (paragraph.text.toPlainText(includeSemanticsLabels: false).isEmpty) {
      if (!_highlightWhenEmpty) return;
      path.addRect(origin & Size(_emptyBlockHighlightWidth, paragraph.size.height));
    } else {
      final selection = _selection;
      if (selection == null || !selection.isValid || selection.isCollapsed) return;
      for (final box in paragraph.getBoxesForSelection(selection, boxHeightStyle: BoxHeightStyle.max)) {
        final rect = box.toRect();
        path.addRect(
          (rect.width > 0 ? rect : Rect.fromLTWH(rect.left, rect.top, _emptyLineHighlightWidth, rect.height)).shift(
            origin,
          ),
        );
      }
    }
    // One fill: where boxes meet or overlap (a line's and the next one's), the color doesn't add up.
    canvas.drawPath(path, Paint()..color = _color);
  }
}
