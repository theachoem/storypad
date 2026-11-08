import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../controller/story_editor_controller.dart';

/// An empty heading line, anywhere in the document, shows [hint] for its level (e.g. "Headline 1") in the heading's own
/// style, in [hintColor]. Not while read-only.
class HeadingHintComponentBuilder extends ParagraphComponentBuilder {
  const HeadingHintComponentBuilder(this.controller, {required this.hint, required this.hintColor});

  final StoryEditorController controller;

  /// The hint for a heading level (1-6) -- [firstLine] for the document's first line, a page's title -- or `null` for
  /// none.
  final String? Function(int level, bool firstLine) hint;

  final Color? Function(BuildContext context) hintColor;

  static final _levels = <Attribution, int>{
    header1Attribution: 1,
    header2Attribution: 2,
    header3Attribution: 3,
    header4Attribution: 4,
    header5Attribution: 5,
    header6Attribution: 6,
  };

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (controller.readOnly || node is! ParagraphNode || node.text.isNotEmpty) return null;
    final level = _levels[node.getMetadataValue(NodeMetadata.blockType)];
    final text = level == null ? null : hint(level, document.getNodeIndexById(node.id) == 0);
    if (text == null) return null;
    return HintComponentViewModel.fromParagraphViewModel(
      super.createViewModel(document, node)! as ParagraphComponentViewModel,
      hintText: text,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    // Hints on a heading line (the page placeholder's too, in the heading's style); a paragraph's go on to the page
    // placeholder's builder.
    if (componentViewModel is! HintComponentViewModel || !_levels.containsKey(componentViewModel.blockType)) {
      return null;
    }
    return TextWithHintComponent(
      key: componentContext.componentKey,
      text: componentViewModel.text,
      textStyleBuilder: componentViewModel.textStyleBuilder,
      hintText: AttributedText(componentViewModel.hintText),
      hintStyleBuilder: (_) =>
          componentViewModel.textStyleBuilder(const {}).copyWith(color: hintColor(componentContext.context)),
      textAlign: componentViewModel.textAlignment,
      textSelection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      underlines: componentViewModel.createUnderlines(),
      metadata: {'blockType': componentViewModel.blockType},
    );
  }
}
