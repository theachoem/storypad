import 'package:super_editor/super_editor.dart';

import '../markdown/markdown_format.dart';

/// A page's title lives in its Markdown: it's the page's **first block, if that block is a heading** (any level). A
/// heading further down -- even after blank lines -- is content, not a title: the editor treats exactly the first
/// block as the title, so the two can't disagree. An empty heading in that place is an empty title (the slot a new
/// page starts with), and it isn't part of the body either.
///
/// Titles are written as [pageTitleLevel] headings (see [pageTitleNode]).

/// The heading level a page title is written as.
const pageTitleLevel = 3;

/// [title] as a page title holds it: line breaks joined with a space, surrounding whitespace trimmed; `null` when
/// nothing is left.
String? normalizePageTitle(String? title) {
  if (title == null) return null;
  final normalized = title.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').trim();
  return normalized.isEmpty ? null : normalized;
}

/// A heading holding [title] (unformatted) as a page's title. [title] is normalized (see [normalizePageTitle]); an
/// empty title makes an empty heading.
ParagraphNode pageTitleNode(String? title, {String? id}) {
  return ParagraphNode(
    id: id ?? Editor.createNodeId(),
    text: AttributedText(normalizePageTitle(title) ?? ''),
    metadata: {NodeMetadata.blockType: headerAttribution(pageTitleLevel)},
  );
}

/// Where a page's title is in [nodes]: the title as plain text (formatting dropped, trimmed; `null` when there's no
/// title or it's empty), and the index of the first body node.
({String? title, int bodyStart}) locatePageTitle(List<DocumentNode> nodes) {
  final first = nodes.firstOrNull;
  if (first is ParagraphNode && headerLevel(first.getMetadataValue(NodeMetadata.blockType)) != null) {
    final text = first.text.toPlainText(includePlaceholders: false).trim();
    return (title: text.isEmpty ? null : text, bodyStart: 1);
  }
  return (title: null, bodyStart: 0);
}
