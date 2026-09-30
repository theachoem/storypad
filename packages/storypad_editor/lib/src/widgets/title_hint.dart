import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../markdown/markdown_format.dart';

/// Shows [hint] in an empty heading that's the document's first block -- an empty page title (see
/// `StoryCodec.pageTitleOf`, the same rule), e.g. the one a new page starts with. Unlike super_editor's
/// `HintComponentBuilder`, it shows whatever follows the heading, and the hint keeps the heading's own style, in
/// [hintColor].
class TitleHintComponentBuilder implements ComponentBuilder {
  const TitleHintComponentBuilder(this.hint, this.hintColor);

  final String hint;

  /// The hint's color. Defaults to the theme's hint color.
  final Color? Function(BuildContext) hintColor;

  static const _delegate = ParagraphComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode || node.text.isNotEmpty) return null;
    if (headerLevel(node.getMetadataValue(NodeMetadata.blockType)) == null) return null;
    if (document.getNodeIndexById(node.id) != 0) return null;

    final viewModel = _delegate.createViewModel(document, node);
    if (viewModel is! ParagraphComponentViewModel) return null;
    return HintComponentViewModel.fromParagraphViewModel(viewModel, hintText: hint);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! HintComponentViewModel) return null;

    final context = componentContext.context;
    return TextWithHintComponent(
      key: componentContext.componentKey,
      text: componentViewModel.text,
      textStyleBuilder: componentViewModel.textStyleBuilder,
      hintText: AttributedText(componentViewModel.hintText),
      hintStyleBuilder: (attributions) => componentViewModel
          .textStyleBuilder(attributions)
          .copyWith(color: hintColor(context) ?? Theme.of(context).hintColor),
      textAlign: componentViewModel.textAlignment,
      textSelection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      underlines: componentViewModel.createUnderlines(),
      metadata: {
        if (componentViewModel.blockType != null) //
          'blockType': componentViewModel.blockType,
      },
    );
  }
}
