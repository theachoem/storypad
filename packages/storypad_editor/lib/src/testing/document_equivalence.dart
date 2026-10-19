import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';
import '../codec/node_description.dart';
import '../markdown/markdown_attributions.dart';

export '../codec/node_description.dart' show NodeDescription;

/// Comparing documents as the Markdown format sees them, for tests.
class DocumentEquivalence {
  const DocumentEquivalence._();

  /// Whether two nodes hold the same content as far as the Markdown format can tell: same kind of block, block type,
  /// alignment, indent, completion, and text (compared per character, ignoring formatting on line breaks and
  /// unsupported attributions; code with line endings normalized). List items and tasks compare alignment too. Ids and
  /// incidental metadata are ignored.
  static bool nodes(DocumentNode a, DocumentNode b) {
    if (a.runtimeType != b.runtimeType) return false;

    return switch ((a, b)) {
      (ParagraphNode a, ParagraphNode b) => _paragraphsEquivalent(a, b),
      (ListItemNode a, ListItemNode b) =>
        a.type == b.type &&
            a.indent == b.indent &&
            _align(a) == _align(b) &&
            MarkdownAttributions.textEquals(a.text, b.text),
      (TaskNode a, TaskNode b) =>
        a.isComplete == b.isComplete &&
            a.indent == b.indent &&
            _align(a) == _align(b) &&
            MarkdownAttributions.textEquals(a.text, b.text),
      (StoryEmbedNode a, StoryEmbedNode b) => a.hasEquivalentContent(b),
      (ImageNode a, ImageNode b) => a.imageUrl == b.imageUrl && a.altText == b.altText,
      (HorizontalRuleNode _, HorizontalRuleNode _) => true,
      _ => a.hasEquivalentContent(b),
    };
  }

  static bool _paragraphsEquivalent(ParagraphNode a, ParagraphNode b) {
    final blockType = _blockType(a);
    if (blockType != _blockType(b)) return false;
    // Code is compared verbatim, except line endings, which the format normalizes to \n.
    if (blockType == codeAttribution) return _lineEndings(a.text.toPlainText()) == _lineEndings(b.text.toPlainText());

    return _align(a) == _align(b) && a.indent == b.indent && MarkdownAttributions.textEquals(a.text, b.text);
  }

  static String _lineEndings(String text) => text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  static Attribution _blockType(DocumentNode node) =>
      node.getMetadataValue(NodeMetadata.blockType) ?? paragraphAttribution;

  static String _align(DocumentNode node) => node.getMetadataValue(TextNodeMetadata.textAlign) ?? 'left';

  /// Matches a document (any `Iterable<DocumentNode>`) equivalent to [expected] node by node (see [nodes]).
  /// Blank lines count, wherever they are: the Markdown format keeps them all.
  static Matcher matcher(Iterable<DocumentNode> expected) => _EquivalentDocument(expected.toList());
}

class _EquivalentDocument extends Matcher {
  _EquivalentDocument(this.expected);

  final List<DocumentNode> expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Iterable<DocumentNode>) return false;
    final actual = item.toList();
    if (actual.length != expected.length) return false;
    for (var i = 0; i < actual.length; i++) {
      if (!DocumentEquivalence.nodes(actual[i], expected[i])) {
        matchState['index'] = i;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
    'a document equivalent to:\n  ${expected.map((node) => NodeDescription(node).describe()).join('\n  ')}',
  );

  @override
  Description describeMismatch(Object? item, Description mismatch, Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! Iterable<DocumentNode>) return mismatch.add('is not a document');
    final actual = item.toList();
    final index = matchState['index'];
    if (index is int) {
      return mismatch.add(
        'differs at node $index:\n  actual:   ${NodeDescription(actual[index]).describe()}\n'
        '  expected: ${NodeDescription(expected[index]).describe()}',
      );
    }
    return mismatch.add(
      'has ${actual.length} nodes:\n  ${actual.map((node) => NodeDescription(node).describe()).join('\n  ')}',
    );
  }
}
