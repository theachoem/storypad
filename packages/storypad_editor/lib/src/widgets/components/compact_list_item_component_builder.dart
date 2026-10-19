import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../document/text_alignment.dart';
import 'compact_indent.dart';

/// Renders bullet/numbered list items with a [CompactIndent.markerColumnWidth]-based
/// indent instead of SuperEditor's much wider stock formula.
///
/// This reuses the stock [UnorderedListItemComponent]/[OrderedListItemComponent]
/// widgets as-is (unlike blockquote's fix, no fork of their internals is
/// needed) — they already accept an `indentCalculator`, the stock
/// [ListItemComponentBuilder] just never varies it from its own default.
class CompactListItemComponentBuilder implements ComponentBuilder {
  const CompactListItemComponentBuilder();

  static const _delegate = ListItemComponentBuilder();

  static double _indentCalculator(TextStyle textStyle, int indent) =>
      CompactIndent.markerColumnWidth + CompactIndent.indentStepWidth * indent;

  /// Stock list items ignore the node's `textAlign`; a Quill story can align any line.
  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    final viewModel = _delegate.createViewModel(document, node);
    final align = TextAlignment.of(node);
    if (viewModel is ListItemComponentViewModel && align != null) viewModel.textAlignment = align;
    return viewModel;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is UnorderedListItemComponentViewModel) {
      return UnorderedListItemComponent(
        componentKey: componentContext.componentKey,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        indent: componentViewModel.indent,
        indentCalculator: _indentCalculator,
        dotStyle: componentViewModel.dotStyle,
        textSelection: componentViewModel.selection,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }

    if (componentViewModel is OrderedListItemComponentViewModel) {
      return OrderedListItemComponent(
        componentKey: componentContext.componentKey,
        indent: componentViewModel.indent,
        indentCalculator: _indentCalculator,
        listIndex: componentViewModel.ordinalValue!,
        text: componentViewModel.text,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        styleBuilder: componentViewModel.textStyleBuilder,
        numeralStyle: componentViewModel.numeralStyle,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }

    return null;
  }
}
