import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'text_selection_highlight.dart';

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
