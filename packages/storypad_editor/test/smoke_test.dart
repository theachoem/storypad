import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

/// Proves the scaffold resolves: the dependencies every later phase builds on (super_editor's Quill + Markdown support,
/// package:markdown) are usable from this package.
void main() {
  test('super_editor parses Quill Delta ops', () {
    final document = parseQuillDeltaOps([
      {'insert': 'Hello'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
    ]);
    addTearDown(document.dispose);

    final node = document.first as ParagraphNode;
    expect(node.text.toPlainText(), 'Hello');
    expect(node.getMetadataValue(NodeMetadata.blockType), header1Attribution);
  });

  test('super_editor round-trips Markdown', () {
    final document = deserializeMarkdownToDocument('# Hello');
    addTearDown(document.dispose);

    expect(serializeDocumentToMarkdown(document, syntax: MarkdownSyntax.normal), '# Hello');
  });

  test('package:markdown is available', () {
    expect(md.markdownToHtml('**bold**'), '<p><strong>bold</strong></p>\n');
  });
}
