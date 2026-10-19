import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

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

  /// The width an empty line's highlight gets, as super_editor's (`TextLayoutEmptyHighlight`, and
  /// `TextSelectionPainter` for an empty line within a selection).
  static const _emptyBlockHighlightWidth = 20.0;

  static const _emptyLineHighlightWidth = 5.0;
}
