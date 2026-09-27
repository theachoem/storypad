import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';
import '../markdown/inline_markdown_writer.dart';
import '../markdown/markdown_format.dart';

/// Whether two nodes hold the same content as far as the Markdown format can tell: same kind of block, block type,
/// alignment, indent, completion, and text (compared per character, ignoring formatting on line breaks and
/// unsupported attributions; code with line endings normalized). Ids and incidental metadata are ignored.
bool nodesEquivalent(DocumentNode a, DocumentNode b) {
  if (a.runtimeType != b.runtimeType) return false;

  return switch ((a, b)) {
    (ParagraphNode a, ParagraphNode b) => _paragraphsEquivalent(a, b),
    (ListItemNode a, ListItemNode b) => a.type == b.type && a.indent == b.indent && inlineTextEquals(a.text, b.text),
    (TaskNode a, TaskNode b) =>
      a.isComplete == b.isComplete && a.indent == b.indent && inlineTextEquals(a.text, b.text),
    (StoryEmbedNode a, StoryEmbedNode b) => a.hasEquivalentContent(b),
    (ImageNode a, ImageNode b) => a.imageUrl == b.imageUrl && a.altText == b.altText,
    (HorizontalRuleNode _, HorizontalRuleNode _) => true,
    _ => a.hasEquivalentContent(b),
  };
}

bool _paragraphsEquivalent(ParagraphNode a, ParagraphNode b) {
  final blockType = _blockType(a);
  if (blockType != _blockType(b)) return false;
  // Code is compared verbatim, except line endings, which the format normalizes to \n.
  if (blockType == codeAttribution) return _lineEndings(a.text.toPlainText()) == _lineEndings(b.text.toPlainText());

  return _align(a) == _align(b) && a.indent == b.indent && inlineTextEquals(a.text, b.text);
}

String _lineEndings(String text) => text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

Attribution _blockType(DocumentNode node) => node.getMetadataValue(NodeMetadata.blockType) ?? paragraphAttribution;

String _align(DocumentNode node) => node.getMetadataValue(TextNodeMetadata.textAlign) ?? 'left';

/// [nodes] as the Markdown format stores them: trailing empty paragraphs dropped.
List<DocumentNode> canonicalNodes(Iterable<DocumentNode> nodes) {
  final list = nodes.toList();
  while (list.isNotEmpty && isEmptyParagraph(list.last)) {
    list.removeLast();
  }
  return list;
}

/// A readable one-line description of [node], for failure messages.
String describeNode(DocumentNode node) {
  final String detail;
  switch (node) {
    case ParagraphNode():
      detail = '${_blockType(node).id} align=${_align(node)} indent=${node.indent} "${node.text.toPlainText()}"';
    case ListItemNode():
      detail = '${node.type.name} indent=${node.indent} "${node.text.toPlainText()}"';
    case TaskNode():
      detail = '[${node.isComplete ? 'x' : ' '}] indent=${node.indent} "${node.text.toPlainText()}"';
    case StoryEmbedNode():
      detail = '${node.type}: ${node.value}';
    default:
      detail = '';
  }
  return '${node.runtimeType}($detail)';
}

/// Matches a document (any `Iterable<DocumentNode>`) equivalent to [expected] node by node (see [nodesEquivalent]),
/// after dropping trailing empty paragraphs from both.
Matcher isEquivalentDocument(Iterable<DocumentNode> expected) => _EquivalentDocument(canonicalNodes(expected));

class _EquivalentDocument extends Matcher {
  _EquivalentDocument(this.expected);

  final List<DocumentNode> expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Iterable<DocumentNode>) return false;
    final actual = canonicalNodes(item);
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (!nodesEquivalent(actual[i], expected[i])) {
        matchState['index'] = i;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('a document equivalent to:\n  ${expected.map(describeNode).join('\n  ')}');

  @override
  Description describeMismatch(Object? item, Description mismatch, Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! Iterable<DocumentNode>) return mismatch.add('is not a document');
    final actual = canonicalNodes(item);
    final index = matchState['index'];
    if (index is int) {
      return mismatch.add(
        'differs at node $index:\n  actual:   ${describeNode(actual[index])}\n'
        '  expected: ${describeNode(expected[index])}',
      );
    }
    return mismatch.add('has ${actual.length} nodes:\n  ${actual.map(describeNode).join('\n  ')}');
  }
}
