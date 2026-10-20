import 'package:super_editor/super_editor.dart';

import '../document/heading.dart';

/// A page's title lives in its Markdown: it's the page's **first block, if that block is a heading** (any level). A
/// heading further down -- even after blank lines -- is content, not a title: the editor treats exactly the first
/// block as the title, so the two can't disagree. An empty heading in that place is an empty title, and it isn't part
/// of the body either.
///
/// A title given on its own (a Quill page's separate title, a template's) is written as a [level] heading (see
/// [node]).
class PageTitle {
  const PageTitle._();

  /// The heading level a page title is written as.
  static const level = 3;

  /// [title] as a page title holds it: line breaks joined with a space, surrounding whitespace trimmed; `null` when
  /// nothing is left.
  static String? normalize(String? title) {
    if (title == null) return null;
    final normalized = title.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').trim();
    return normalized.isEmpty ? null : normalized;
  }

  /// A heading holding [title] (unformatted, normalized: see [normalize]) as a page's title.
  static ParagraphNode node(String title) {
    return ParagraphNode(
      id: Editor.createNodeId(),
      text: AttributedText(normalize(title) ?? ''),
      metadata: {NodeMetadata.blockType: Heading.blockType(level)},
    );
  }

  /// Where a page's title is in [nodes]: the title as plain text (formatting dropped, trimmed; `null` when there's no
  /// title or it's empty), and the index of the first body node.
  static ({String? title, int bodyStart}) locate(List<DocumentNode> nodes) {
    final first = nodes.firstOrNull;
    if (first is ParagraphNode && Heading.levelOf(first.getMetadataValue(NodeMetadata.blockType)) != null) {
      final text = first.text.toPlainText(includePlaceholders: false).trim();
      return (title: text.isEmpty ? null : text, bodyStart: 1);
    }
    return (title: null, bodyStart: 0);
  }
}
