import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'compact_indent.dart';

/// Renders paragraphs (which, per SuperEditor's model, also covers
/// headings, blockquotes, and code blocks — they're all `ParagraphNode`
/// with a different `blockType` metadata) with the [CompactIndent.indentStepWidth]
/// step list items and tasks use too, instead of SuperEditor's much wider stock
/// formula (`(fontSize * 0.6) * 4` per level).
///
/// Unlike [CompactTaskComponentBuilder], this only needs to override
/// [createViewModel] — `ParagraphComponentViewModel.internalCopy` (unlike
/// `TaskComponentViewModel`'s) already carries `indentCalculator` over on
/// every `copy()`, so there's no need to fork [ParagraphComponent] itself
/// just to keep the override from being silently reset.
class CompactParagraphComponentBuilder implements ComponentBuilder {
  const CompactParagraphComponentBuilder();

  static const _delegate = ParagraphComponentBuilder();

  static double _indentCalculator(TextStyle textStyle, int indent) => CompactIndent.indentStepWidth * indent;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    final viewModel = _delegate.createViewModel(document, node);
    if (viewModel is ParagraphComponentViewModel) {
      viewModel.indentCalculator = _indentCalculator;
    }
    return viewModel;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) => _delegate.createComponent(componentContext, componentViewModel);
}
