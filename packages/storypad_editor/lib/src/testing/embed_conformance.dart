import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../codec/story_codec.dart';
import '../embed/story_embed_codec.dart';
import '../embed/story_embed_node.dart';
import '../embed/unknown_embed.dart';
import 'document_equivalence.dart';
import 'quill_equivalence.dart';

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
/// - its plain text is consistent;
/// - if the embed has a Quill form ([StoryEmbedCodec.quillKeys]), [StoryEmbedCodec.toQuill] writes [value] under one
///   of its keys, and that op imports back as [value] (so a document edited here can be stored as Quill);
/// - if [fromQuillOp] is given (a Quill embed op, e.g. `{'insert': {'media': 'a.jpg'}}`), that op imports as
///   [value], converts to the same Markdown, and writing it back as Quill gives an equivalent op.
///
/// [otherEmbeds] are registered alongside [embed], to check tags and keys don't collide with the app's other embeds.
void expectEmbedRoundTrip<T extends Object>(
  StoryEmbedCodec<T> embed,
  T value, {
  Map<String, Object?>? fromQuillOp,
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

  if (fromQuillOp != null) {
    final ops = [
      fromQuillOp,
      {'insert': '\n'},
    ];
    final imported = codec.decodeQuill(ops);
    expect(imported, hasLength(1), reason: '$fromQuillOp must import as one node, got: ${imported.map(describeNode)}');
    expect(
      imported.single,
      isA<StoryEmbedNode>().having((node) => node.type, 'type', embed.type),
      reason:
          '$fromQuillOp imported as ${describeNode(imported.single)}, not a "${embed.type}" embed. Is its key in '
          'quillKeys (${embed.quillKeys}), and does fromQuill accept it?',
    );
    expect(
      embed.valueOf(imported.single as StoryEmbedNode),
      value,
      reason: '$fromQuillOp imported as a different value',
    );
    expect(codec.quillToMarkdown(ops), markdown);
    expect(codec.encodeQuill(imported), isEquivalentQuill(ops, codec), reason: 'writing $fromQuillOp back as Quill');
  }

  if (embed.quillKeys.isNotEmpty) {
    final op = embed.toQuill(value);
    expect(
      op,
      isNotNull,
      reason: '${embed.type} imports Quill ${embed.quillKeys}, so toQuill must write $value back as a Quill op',
    );
    expect(embed.quillKeys, contains(op!.key), reason: 'toQuill must write one of the keys fromQuill reads');
    final ops = [
      op.toJson(),
      {'insert': '\n'},
    ];
    final imported = codec.decodeQuill(ops);
    expect(
      imported.length == 1 && imported.single is StoryEmbedNode
          ? embed.valueOf(imported.single as StoryEmbedNode)
          : imported,
      value,
      reason: 'toQuill wrote ${op.toJson()}, which imports as a different value',
    );
    expect(codec.encodeQuill([node]), ops, reason: 'encodeQuill must write toQuill\'s op');
  }

  final surrounded = [
    ParagraphNode(id: Editor.createNodeId(), text: AttributedText('before')),
    embed.createNode(value),
    ListItemNode.unordered(id: Editor.createNodeId(), text: AttributedText('after')),
  ];
  final surroundedMarkdown = codec.encode(surrounded);
  expect(codec.decodeNodes(surroundedMarkdown), isEquivalentDocument(surrounded), reason: surroundedMarkdown);
}
