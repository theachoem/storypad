import 'dart:math';

import 'package:flutter/painting.dart' show Color;
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import 'test_embeds.dart';

/// Seeded generators for randomized round-trip tests. Deliberately include characters that are Markdown or HTML
/// syntax, so escaping is exercised.

const _alphabet = 'ab c(). ,!?-_*~`#[]<>&\\\'"|:1+=\t/u\r\u2028\u2029é';

final _attributions = <Attribution>[
  boldAttribution,
  italicsAttribution,
  strikethroughAttribution,
  underlineAttribution,
  codeAttribution,
  const LinkAttribution('https://example.com/a_b'),
  const LinkAttribution('a b)'),
  const ColorAttribution(Color(0xFF336699)),
  const BackgroundColorAttribution(Color(0x80FFCC00)),
  const ScriptAttribution.superscript(),
  const ScriptAttribution.subscript(),
  const LinkAttribution('mailto:a@b.c?subject=x y'),
  const LinkAttribution('/relative/(path)'),
];

String randomString(Random random, {int maxLength = 14, bool lineBreaks = true}) {
  final alphabet = lineBreaks ? '$_alphabet\n' : _alphabet;
  final length = random.nextInt(maxLength + 1);
  return List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)]).join();
}

AttributedText randomText(Random random, {int maxLength = 14, bool lineBreaks = true}) {
  final text = AttributedText(randomString(random, maxLength: maxLength, lineBreaks: lineBreaks));
  final length = text.length;
  if (length == 0) return text;

  for (var i = random.nextInt(4); i > 0; i--) {
    final start = random.nextInt(length);
    final end = start + random.nextInt(length - start);
    final attribution = _attributions[random.nextInt(_attributions.length)];
    // Mirror the editor: conflicting attributions (two links, two colors) can't overlap.
    final conflicts = text.getAttributionSpansInRange(
      attributionFilter: (candidate) => candidate.id == attribution.id && candidate != attribution,
      range: SpanRange(start, end),
    );
    if (conflicts.isEmpty) text.addAttribution(attribution, SpanRange(start, end));
  }
  return text;
}

const _blockTypes = [
  paragraphAttribution,
  header1Attribution,
  header3Attribution,
  header6Attribution,
  blockquoteAttribution,
  codeAttribution,
];

const _aligns = [null, 'left', 'center', 'right', 'justify'];

/// A random text-only document of up to [maxNodes] blocks.
List<DocumentNode> randomTextDocument(Random random, {int maxNodes = 8}) {
  return [for (var i = 1 + random.nextInt(maxNodes); i > 0; i--) randomTextNode(random)];
}

DocumentNode randomTextNode(Random random) {
  String id() => Editor.createNodeId();

  switch (random.nextInt(7)) {
    case 0:
      return ListItemNode(
        id: id(),
        itemType: random.nextBool() ? ListItemType.ordered : ListItemType.unordered,
        text: randomText(random),
        indent: random.nextInt(4),
      );
    case 1:
      return TaskNode(id: id(), text: randomText(random), isComplete: random.nextBool(), indent: random.nextInt(4));
    case 2:
      return HorizontalRuleNode(id: id());
    case 3:
      // An empty paragraph (not at the end, it would be trimmed, which the equivalence check allows for).
      return ParagraphNode(id: id(), text: AttributedText());
    default:
      final blockType = _blockTypes[random.nextInt(_blockTypes.length)];
      if (blockType == codeAttribution) {
        return ParagraphNode(
          id: id(),
          text: AttributedText(randomString(random, maxLength: 20).replaceAll('\t', '    ')),
          metadata: const {NodeMetadata.blockType: codeAttribution},
        );
      }
      final align = _aligns[random.nextInt(_aligns.length)];
      return ParagraphNode(
        id: id(),
        text: randomText(random),
        indent: random.nextInt(3) == 0 ? random.nextInt(4) : 0,
        metadata: {NodeMetadata.blockType: blockType, TextNodeMetadata.textAlign: ?align},
      );
  }
}

/// A random document mixing text blocks and the test embeds (plus unknown values).
List<DocumentNode> randomDocumentWithEmbeds(Random random, {int maxNodes = 10}) {
  return [
    for (var i = 1 + random.nextInt(maxNodes); i > 0; i--)
      random.nextInt(3) == 0 ? randomEmbedNode(random) : randomTextNode(random),
  ];
}

StoryEmbedNode randomEmbedNode(Random random) {
  switch (random.nextInt(3)) {
    case 0:
      final name = randomString(random, lineBreaks: false);
      return const StickerEmbedCodec().createNode(name.isEmpty ? 'x' : name);
    case 1:
      final paths = [
        for (var i = 1 + random.nextInt(3); i > 0; i--)
          // No "|": it separates paths in the Quill form (StoryPad's asset paths never contain one).
          'images/${randomString(random, maxLength: 6, lineBreaks: false).replaceAll('|', '')}.jpg',
      ];
      return const GalleryEmbedCodec().createNode(
        GalleryValue(
          paths,
          alignment: GalleryAlignment.values[random.nextInt(GalleryAlignment.values.length)],
          size: GallerySize.values[random.nextInt(GallerySize.values.length)],
        ),
      );
    default:
      return const UnknownEmbedCodec().createNode(
        UnknownQuillEmbed({
          'insert': {randomString(random, lineBreaks: false): randomString(random)},
          'attributes': {'x': random.nextInt(9)},
        }),
      );
  }
}
