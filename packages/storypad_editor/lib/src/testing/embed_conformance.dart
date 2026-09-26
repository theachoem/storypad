import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../codec/story_codec.dart';
import '../embed/story_embed_codec.dart';
import '../embed/story_embed_node.dart';
import '../embed/unknown_embed.dart';
import 'document_equivalence.dart';

/// Checks that [embed] stores [value] losslessly, the way the editor will use it. Call it once per interesting value
/// (defaults, every attribute, edge cases) from the app's own tests:
///
/// ```dart
/// test('media embed', () {
///   expectEmbedRoundTrip(const MediaEmbed(), MediaValue(['images/a.jpg'], alignment: EmbedAlignment.center));
/// });
/// ```
///
/// Verifies that:
/// - the embed is written as one Markdown line, reads back as an equal value (a new instance, so this also catches a
///   value type without `==`), and re-writes identically (a fixed point);
/// - it survives between other blocks, with its line separated from theirs;
/// - its plain text is consistent.
///
/// [otherEmbeds] are registered alongside [embed], to check tags and keys don't collide with the app's other embeds.
void expectEmbedRoundTrip<T extends Object>(
  StoryEmbedCodec<T> embed,
  T value, {
  List<StoryEmbedCodec> otherEmbeds = const [],
}) {
  final codec = embed is UnknownEmbedCodec
      ? StoryCodec(embeds: otherEmbeds, unknown: embed as UnknownEmbedCodec)
      : StoryCodec(embeds: [embed, ...otherEmbeds]);
  final node = embed.createNode(value);

  final markdown = codec.encode([node]);
  expect(markdown, isNot(contains('\n')), reason: '${embed.type} must be written as a single line, got:\n$markdown');

  final decoded = codec.decodeNodes(markdown);
  expect(decoded, hasLength(1), reason: '"$markdown" must read back as one node, got: ${decoded.map(describeNode)}');
  final decodedNode = decoded.single;
  expect(
    decodedNode,
    isA<StoryEmbedNode>().having((node) => node.type, 'type', embed.type),
    reason:
        '"$markdown" read back as ${describeNode(decodedNode)}, not a "${embed.type}" embed. Is its tag listed in '
        'htmlTags (${embed.htmlTags}), and does fromHtml accept it?',
  );
  final decodedValue = embed.valueOf(decodedNode as StoryEmbedNode);
  expect(
    decodedValue,
    value,
    reason: '"$markdown" read back as a different value. Does ${value.runtimeType} implement == and hashCode?',
  );
  expect(decodedValue.hashCode, value.hashCode, reason: 'equal values must have equal hash codes');
  expect(codec.encode(decoded), markdown, reason: 'writing the read-back value must give identical Markdown');
  expect((decodedNode).plainText, embed.toPlainText(value));

  final surrounded = [
    ParagraphNode(id: Editor.createNodeId(), text: AttributedText('before')),
    embed.createNode(value),
    ListItemNode.unordered(id: Editor.createNodeId(), text: AttributedText('after')),
  ];
  final surroundedMarkdown = codec.encode(surrounded);
  expect(codec.decodeNodes(surroundedMarkdown), isEquivalentDocument(surrounded), reason: surroundedMarkdown);
}
