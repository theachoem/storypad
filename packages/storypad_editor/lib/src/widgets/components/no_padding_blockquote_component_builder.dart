import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Renders blockquotes without [BlockquoteComponent]'s built-in
/// `EdgeInsets.symmetric(horizontal: 16, vertical: 16)` container padding.
///
/// That padding is a literal inside the stock widget's `build()`, not read
/// from the stylesheet's `Styles.padding` the way every other block's
/// spacing is — so it survives [RawEditor]'s stylesheet, which gives every
/// block its padding from `StoryEditorSpacing` (none at the sides), leaving
/// the blockquote both visibly inset compared to its flush neighbors, and out
/// of step with
/// `ReorderableDocumentOverlay`'s drag handle (which aligns to the node's
/// rendered left edge, i.e. this padding's outer edge, not the text inside
/// it).
///
/// This is a near-identical copy of `BlockquoteComponentBuilder` — same view
/// model, same layout (an indent-spacer + the text) — with that one literal
/// dropped. Swap it in for the stock builder via `SuperEditor.componentBuilders`.
class NoPaddingBlockquoteComponentBuilder implements ComponentBuilder {
  const NoPaddingBlockquoteComponentBuilder();

  static const _delegate = BlockquoteComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      _delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! BlockquoteComponentViewModel) {
      return null;
    }

    return _NoPaddingBlockquoteComponent(
      textKey: componentContext.componentKey,
      text: componentViewModel.text,
      styleBuilder: componentViewModel.textStyleBuilder,
      indent: componentViewModel.indent,
      indentCalculator: componentViewModel.indentCalculator,
      textAlign: componentViewModel.textAlignment,
      backgroundColor: componentViewModel.backgroundColor,
      borderRadius: componentViewModel.borderRadius,
      textSelection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
      underlines: componentViewModel.createUnderlines(),
    );
  }
}

class _NoPaddingBlockquoteComponent extends StatelessWidget {
  const _NoPaddingBlockquoteComponent({
    required this.textKey,
    required this.text,
    required this.styleBuilder,
    this.textSelection,
    this.indent = 0,
    this.indentCalculator = defaultParagraphIndentCalculator,
    this.selectionColor = Colors.lightBlueAccent,
    required this.backgroundColor,
    required this.borderRadius,
    this.highlightWhenEmpty = false,
    this.underlines = const [],
    this.textAlign = TextAlign.left,
  });

  final TextAlign textAlign;
  final GlobalKey textKey;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final TextSelection? textSelection;
  final int indent;
  final TextBlockIndentCalculator indentCalculator;
  final Color selectionColor;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final bool highlightWhenEmpty;
  final List<Underlines> underlines;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, color: backgroundColor),
        child: Row(
          children: [
            // Indent spacing on left.
            SizedBox(width: indentCalculator(styleBuilder({}), indent)),
            // The actual paragraph UI.
            Expanded(
              child: TextComponent(
                key: textKey,
                text: text,
                textAlign: textAlign,
                textStyleBuilder: styleBuilder,
                textSelection: textSelection,
                selectionColor: selectionColor,
                highlightWhenEmpty: highlightWhenEmpty,
                underlines: underlines,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
